class Environment < ActiveRecord::Base
  belongs_to :application
  has_many   :instances
  validates_presence_of :name
end
