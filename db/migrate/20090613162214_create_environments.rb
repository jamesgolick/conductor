class CreateEnvironments < ActiveRecord::Migration
  def self.up
    create_table :environments, :force => true do |t|
      t.integer :application_id
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :environments
  end
end
