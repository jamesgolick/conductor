class RemoveTableChefLogs < ActiveRecord::Migration
  def self.up
    drop_table :chef_logs
  end

  def self.down
    create_table :chef_logs do |t|
      t.integer  "instance_id"
      t.boolean  "successful"
      t.text     "body"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
