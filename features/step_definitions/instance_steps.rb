Given /^that I've launched a (.+) instance in (.+)$/ do |instance_type, env_name|
  Factory(instance_type.to_sym, 
            :environment => Environment.find_by_name(env_name))
end

When /^I create an? "(.+)" instance$/ do |type|
  env = Environment.find_by_name("production")
  visit application_environment_url(env.application, env)
  click_link "Launch Instance"
  select type,         :from => "Role"
  select "c1_medium",  :from => "Size"
  select "us_east_1c", :from => "Availability Zone"
  click_button "Launch"
end

