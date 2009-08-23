class AddExitCodeToDeployments < ActiveRecord::Migration
  def self.up
    add_column :deployments, :exit_code, :integer
  end

  def self.down
    remove_column :deployments, :exit_code
  end
end
