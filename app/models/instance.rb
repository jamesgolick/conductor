class Instance < ActiveRecord::Base
  class << self
    def ami_for(instance_size)
      %w(m1.small c1.medium).include?(instance_size) ? "ami-b6a241df" : "ami-4aa94a23"
    end

    def deployment_event_map
      {:start      => "deploying",
       :successful => "deployed",
       :failure    => "deployment_failed",
       :cancelled  => "deployment_cancelled"}
    end
  end

  belongs_to :environment

  has_many   :chef_logs
  has_many   :bootstrap_logs
  has_many   :chef_logs

  has_one    :address

  delegate   :application, :to => :environment

  enum_field :size,         %w( m1.small m1.large m1.xlarge c1.medium c1.xlarge )
  enum_field :role,         %w( mysql_master app )
  enum_field :zone,         %w( us-east-1a us-east-1b us-east-1c us-east-1d )
  enum_field :aws_state,    %w( pending running terminating ),          :allow_nil => true
  enum_field :config_state, %w( unconfigured bootstrapping bootstrapped 
                                deploying deployment_failed deployed 
                                deployment_cancelled bootstrap_failed), 
                            :allow_nil => true

  validate :database_server_is_running

  after_create   :launch_ec2_instance, :launch_wait_for_state_change_job, 
                 :notify_environment_of_launch
  before_destroy :set_state_to_terminating, :terminate_ec2_instance, 
                 :notify_environment_of_termination

  named_scope    :running,    :conditions => {:aws_state    => "running"}
  named_scope    :app,        :conditions => {:role         => "app"}
  named_scope    :configured, :conditions => {:configured   => true}

  delegate       :cookbook_repository, :to => :environment

  def update_instance_state
    details = aws_instance_details
    update_attributes :dns_name         => details[:dns_name],
                      :private_dns_name => details[:private_dns_name],
                      :zone             => details[:aws_availability_zone],
                      :aws_state        => details[:aws_state]
    if running?
      deploy
      environment.notify_of(:running, self)
    end
  end

  def aws_state_changed?
    aws_instance_details[:aws_state] != aws_state
  end

  def wait_for_state_change
    while true do
      if aws_state_changed?
        update_instance_state
        break
      end
    end
  end

  def connection_string
    "root@#{public_address}"
  end

  def dna
    @dna ||= Dna.new(environment, role, cookbook_repository, self)
  end

  def assign_address!(address)
    address.update_attributes :instance => self
    ec2.associate_address(instance_id, address.address)
  end

  def public_address
    address.nil? ? dns_name : address.address
  end

  def deployment_event(runner, event)
    state = self.class.deployment_event_map[event]
    update_attribute :config_state, state
    update_attribute :configured, true if state == "deployed"
  end

  def deploy
    ChefDeploymentRunner.new(self).perform_deployment
  end

  protected
    def database_server_is_running
      if !environment.nil? && !mysql_master? && !environment.has_database_server?
        errors.add(:base, "You must launch a database server before you can launch an app server")
      end
    end

    def launch_ec2_instance
      instance = ec2.run_instances :groups            => ['default'],
                                   :keypair           => 'conductor-keypair',
                                   :ami               => self.class.ami_for(size),
                                   :instance_type     => size,
                                   :availability_zone => zone
      update_attributes :instance_id  => instance.first[:aws_instance_id],
                        :aws_state    => 'pending',
                        :config_state => 'unconfigured'
    end

    def terminate_ec2_instance
      ec2.terminate_instances instance_id
    end

    def ec2
      @ec2 ||= Ec2.new
    end

    def aws_instance_details
      ec2.describe_instances(instance_id).first
    end

    def launch_wait_for_state_change_job
      send_later(:wait_for_state_change)
    end

    def notify_environment_of_launch
      environment.notify_of(:launch, self)
    end

    def notify_environment_of_termination
      environment.notify_of(:termination, self)
    end

    def set_state_to_terminating
      update_attribute :aws_state, "terminating"
    end
end
