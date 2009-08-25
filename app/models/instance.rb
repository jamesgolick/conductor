class Instance < ActiveRecord::Base
  class WaitForConfiguredDbServer < RuntimeError; end

  class << self
    def ami_for(instance_size)
      %w(m1.small c1.medium).include?(instance_size) ? "ami-ef48af86" : "ami-e257b08b"
    end
  end

  belongs_to :environment

  has_many   :chef_logs
  has_many   :bootstrap_deployments
  has_many   :chef_deployments

  has_one    :address

  delegate   :application, :to => :environment

  enum_field :size,         %w( m1.small m1.large m1.xlarge c1.medium c1.xlarge )
  enum_field :role,         %w( mysql_master app )
  enum_field :zone,         %w( us-east-1a us-east-1b us-east-1c us-east-1d )
  enum_field :aws_state,    %w( pending running ),              :allow_nil => true
  enum_field :config_state, %w( unconfigured bootstrapping bootstrapped 
                                deploying deployment_failed deployed ), :allow_nil => true

  validate :database_server_is_running

  after_create   :launch_ec2_instance, :launch_wait_for_state_change_job, :notify_environment_of_launch
  before_destroy :terminate_ec2_instance, :notify_environment_of_termination

  named_scope    :running,    :conditions => {:aws_state    => "running"}
  named_scope    :configured, :conditions => {:config_state => "deployed"}
  named_scope    :app,        :conditions => {:role         => "app"}

  def bootstrapped!
    update_attribute :config_state, 'bootstrapped'
    deploy
  end

  def bootstrapping!
    update_attribute :config_state, 'bootstrapping'
  end

  def deploying!
    assert_ready_for_deployment
    update_attribute :config_state, "deploying"
  end

  def deployed!
    update_attribute :config_state, "deployed"
  end

  def deployment_failed!
    update_attribute :config_state, "deployment_failed"
  end

  def update_instance_state
    details = aws_instance_details
    update_attributes :dns_name         => details[:dns_name],
                      :private_dns_name => details[:private_dns_name],
                      :zone             => details[:aws_availability_zone],
                      :aws_state        => details[:aws_state]
    bootstrap if running?
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
    "root@#{dns_name}"
  end

  def bootstrap
    bootstrap_deployments.create
  end

  # TODO: do something way better with this, like probably put it in an Application model which has_many environments
  def cookbook_repository
    @cookbook_repository ||= CookbookRepository.new("git@github.com:giraffesoft/conductor-cookbooks.git")
  end

  def dna
    @dna ||= Dna.new(environment, role, cookbook_repository)
  end

  def deploy
    chef_deployments.create
  end

  def ready_for_deployment?
    !app? || environment.has_configured_db_server?
  end

  def assign_address!(address)
    address.update_attributes :instance => self
    ec2.associate_address(instance_id, address.address)
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

    def assert_ready_for_deployment
      unless ready_for_deployment?
        raise WaitForConfiguredDbServer, "Waiting for a configured db server."
      end
    end

    def notify_environment_of_launch
      environment.notify_of(:launch, self)
    end

    def notify_environment_of_termination
      environment.notify_of(:termination, self)
    end
end
