class CreateAddresses < ActiveRecord::Migration
  def self.up
    create_table :addresses do |t|
      t.integer :environment_id
      t.integer :instance_id
      t.string :address

      t.timestamps
    end
  end

  def self.down
    drop_table :addresses
  end
end
