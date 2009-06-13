class Environment < ActiveRecord::Base
  belongs_to :application
  has_many   :instances
  validates_presence_of :name

  def has_database_server?
    instances.any?(&:mysql_master?)
  end
end
