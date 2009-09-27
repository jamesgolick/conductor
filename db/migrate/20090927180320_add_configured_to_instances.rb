class AddConfiguredToInstances < ActiveRecord::Migration
  def self.up
    add_column :instances, :configured, :boolean, :default => false
  end

  def self.down
    remove_column :instances, :configured
  end
end
