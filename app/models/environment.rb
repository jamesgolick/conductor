class Environment < ActiveRecord::Base
  belongs_to :application
  validates_presence_of :name
end
