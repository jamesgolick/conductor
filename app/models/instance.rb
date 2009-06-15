class Instance < ActiveRecord::Base
  class << self
    def ami_for(instance_size)
      %w(m1_small c1_medium).include?(instance_size) ? "ami-ef48af86" : "ami-e257b08b"
    end
  end

  belongs_to :environment
  delegate   :application, :to => :environment

  enum_field :size,   %w( m1_small m1_large m1_xlarge c1_medium c1_xlarge )
  enum_field :role,   %w( mysql_master app_server )
  enum_field :zone,   %w( us_east_1a us_east_1b us_east_1c us_east_1d )
  enum_field :status, %w( pending running ), :allow_nil => true

  validate :database_server_is_running

  after_create :launch_ec2_instance

  def running!(attrs)
    update_attributes :dns_name         => attrs[:dns_name],
                      :private_dns_name => attrs[:private_dns_name],
                      :status           => 'running'
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
      update_attributes :instance_id => instance[:aws_instance_id],
                        :status      => 'pending'
    end

    def ec2
      @ec2 ||= Ec2.new
    end
end
