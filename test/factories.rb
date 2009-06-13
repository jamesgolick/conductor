Factory.define :application do |a|
  a.name      "SomeApp"
  a.clone_url "git@github.com/somebody/some-app.git"
end

Factory.define :environment do |e|
  e.association :application
  e.name "production"
end

