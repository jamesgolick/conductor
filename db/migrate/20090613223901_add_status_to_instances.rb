class AddStatusToInstances < ActiveRecord::Migration
  def self.up
    add_column :instances, :status, :string
  end

  def self.down
    remove_column :instances, :status
  end
end
