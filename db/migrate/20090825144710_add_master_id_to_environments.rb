class AddMasterIdToEnvironments < ActiveRecord::Migration
  def self.up
    add_column :environments, :master_id, :integer
  end

  def self.down
    remove_column :environments, :master_id
  end
end
