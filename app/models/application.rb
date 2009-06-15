class Application < ActiveRecord::Base
  has_many :environments
  validates_presence_of :name, :clone_url, :cookbook_clone_url
end
