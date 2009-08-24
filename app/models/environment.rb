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

  validates_presence_of :name

  def has_database_server?
    instances.any?(&:mysql_master?)
  end
end
