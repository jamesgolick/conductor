class CreateVolumes < ActiveRecord::Migration
  def self.up
    create_table :volumes do |t|
      t.integer :environment_id
      t.string :role
      t.integer :instance_id
      t.integer :size
      t.string :zone
      t.string :state

      t.timestamps
    end
  end

  def self.down
    drop_table :volumes
  end
end
