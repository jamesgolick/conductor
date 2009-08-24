class AddDomainToEnvironment < ActiveRecord::Migration
  def self.up
    add_column :environments, :domain, :string
  end

  def self.down
    remove_column :environments, :domain
  end
end
