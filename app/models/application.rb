class Application < ActiveRecord::Base
  validates_presence_of :name, :clone_url
end
