class Environment < ActiveRecord::Base
  belongs_to :application

  has_many   :instances do
    def to_dna
      running.inject({}) do |memo, instance|
        memo[instance.role.to_sym] ||= []
        memo[instance.role.to_sym] << instance.private_dns_name
        memo
      end
    end
  end

  has_one :address
  belongs_to :master, :class_name => "Instance"

  validates_presence_of :name
  validates_presence_of :domain

  def has_database_server?
    instances.any?(&:mysql_master?)
  end

  def has_configured_db_server?
    instances.any? { |i| i.mysql_master? && i.deployed? }
  end

  def to_dna
    {
      :apps       => [application.name],
      :rails_env  => name,
      :servers    => instances.to_dna,
      :app_domain => domain,
      :user       => application.name
    }
  end

  def instance_event(event, instance)
    if event == :launch && assign_address_to?(instance)
      instance.attach_address!(address)
    end
  end

  def assign_address_to?(instance)
    instance.app? && instances.count == 1
  end

  def acquire_new_master
    unless next_potential_master.nil?
      self.class.update_all "master_id = #{next_potential_master.id}", 
                            "master_id IS NULL AND id = #{id}"
      reload
    end
  end

  protected
    def next_potential_master
      instances.app.first
    end
end
