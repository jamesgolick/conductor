class AddDnsNameAndPrivateDnsNameToInstances < ActiveRecord::Migration
  def self.up
    add_column :instances, :dns_name, :string
    add_column :instances, :private_dns_name, :string
  end

  def self.down
    remove_column :instances, :private_dns_name
    remove_column :instances, :dns_name
  end
end
