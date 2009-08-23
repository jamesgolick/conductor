class CreateDeployments < ActiveRecord::Migration
  def self.up
    create_table :deployments do |t|
      t.string :type
      t.integer :instance_id
      t.text :log

      t.timestamps
    end
  end

  def self.down
    drop_table :deployments
  end
end
