class Instance < ActiveRecord::Base
  class << self
    def ami_for(instance_size)
      %w(m1.small c1.medium).include?(instance_size) ? "ami-ef48af86" : "ami-e257b08b"
    end
  end

  belongs_to :environment
  has_many   :chef_logs
  has_many   :bootstrap_deployments
  delegate   :application, :to => :environment

  enum_field :size,      %w( m1.small m1.large m1.xlarge c1.medium c1.xlarge )
  enum_field :role,      %w( mysql_master app_server )
  enum_field :zone,      %w( us-east-1a us-east-1b us-east-1c us-east-1d )
  enum_field :aws_state, %w( pending running ),              :allow_nil => true
  enum_field :state,     %w( unconfigured bootstrapped ), :allow_nil => true

  validate :database_server_is_running

  after_create   :launch_ec2_instance, :launch_wait_for_state_change_job
  before_destroy :terminate_ec2_instance

  def bootstrapped!
    update_attribute :state, 'bootstrapped'
  end

  def update_instance_state
    details = aws_instance_details
    update_attributes :dns_name         => details[:dns_name],
                      :private_dns_name => details[:private_dns_name],
                      :zone             => details[:aws_availability_zone],
                      :aws_state        => details[:aws_state]
    launch_bootstrap_job if running?
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
    @dna ||= Dna.new(role, cookbook_repository)
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
      update_attributes :instance_id => instance.first[:aws_instance_id],
                        :aws_state   => 'pending'
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

    def launch_bootstrap_job
      send_later(:bootstrap)
    end
end
