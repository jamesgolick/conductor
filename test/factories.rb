Factory.define :application do |a|
  a.name      "SomeApp"
  a.clone_url "git@github.com/somebody/some-app.git"
  a.cookbook_clone_url "git@github.com/somebody/some-app.git"
end

Factory.define :environment do |e|
  e.association :application
  e.name "production"
end

Factory.define :instance do |i|
  i.association :environment
  i.size "m1.small"
  i.role "app_server"
  i.zone "us-east-1c"
end

Factory.define :app_server, :parent => :instance do
end

Factory.define :mysql_master, :parent => :instance do |m|
  m.role "mysql_master"
end

Factory.define :running_instance, :parent => :instance do |m|
  m.state "running"
  m.role "mysql_master"
  m.dns_name "123.amazonaws.com"
  m.private_dns_name "private.internal.amzn.com"
end

Factory.define :bootstrapped_instance, :parent => :running_instance do |i|
  i.status "bootstrapped"
end

