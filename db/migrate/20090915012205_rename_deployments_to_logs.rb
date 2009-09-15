class RenameDeploymentsToLogs < ActiveRecord::Migration
  def self.up
    rename_table :deployments, :logs
  end

  def self.down
    rename_table :logs, :deployments
  end
end
