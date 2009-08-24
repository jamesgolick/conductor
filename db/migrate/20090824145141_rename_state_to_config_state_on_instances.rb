class RenameStateToConfigStateOnInstances < ActiveRecord::Migration
  def self.up
    rename_column :instances, :state, :config_state
  end

  def self.down
    rename_column :instances, :config_state, :state
  end
end
