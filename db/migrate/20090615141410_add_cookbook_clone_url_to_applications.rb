class AddCookbookCloneUrlToApplications < ActiveRecord::Migration
  def self.up
    add_column :applications, :cookbook_clone_url, :string
  end

  def self.down
    remove_column :applications, :cookbook_clone_url
  end
end
