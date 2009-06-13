class AddInstanceIdToInstances < ActiveRecord::Migration
  def self.up
    add_column :instances, :instance_id, :string
  end

  def self.down
    remove_column :instances, :instance_id
  end
end
