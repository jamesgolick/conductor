class Instance < ActiveRecord::Base
  belongs_to :environment

  validates_presence_of :size
  validates_presence_of :role
  validates_presence_of :zone
end
