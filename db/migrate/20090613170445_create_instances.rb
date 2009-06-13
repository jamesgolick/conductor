class CreateInstances < ActiveRecord::Migration
  def self.up
    create_table :instances, :force => true do |t|
      t.integer :environment_id
      t.string :size
      t.string :zone
      t.string :role

      t.timestamps
    end
  end

  def self.down
    drop_table :instances
  end
end
