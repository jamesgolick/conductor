class AddAwsStateToInstances < ActiveRecord::Migration
  def self.up
    add_column :instances, :aws_state, :string
  end

  def self.down
    remove_column :instances, :aws_state
  end
end
