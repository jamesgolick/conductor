class RenameStatusToStateOnInstances < ActiveRecord::Migration
  def self.up
    rename_column :instances, :status, :state
  end

  def self.down
    rename_column :instances, :state, :status
  end
end
