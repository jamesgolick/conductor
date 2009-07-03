class CreateChefLogs < ActiveRecord::Migration
  def self.up
    create_table :chef_logs do |t|
      t.integer :instance_id
      t.boolean :successful
      t.text :body

      t.timestamps
    end
  end

  def self.down
    drop_table :chef_logs
  end
end
