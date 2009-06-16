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
  i.size "m1_small"
  i.role "app_server"
  i.zone "us_east_1c"
end

Factory.define :app_server, :parent => :instance do
end

Factory.define :mysql_master, :parent => :instance do |m|
  m.role "mysql_master"
end

Factory.define :running_instance, :parent => :instance do |m|
  m.status "running"
  m.role "mysql_master"
end
