Given %r{^that I've launched a (.+) instance in (.+)$} do |instance_type, env_name|
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

Then %r{^(\d+|no) instances? should be running$} do |number|
  number = number == "no" ? 0 : number.to_i
  assert_equal number, Ec2.test_mode_calls[:run_instances].length
end

Then /^the instance should be terminated$/ do
  assert Ec2.test_mode_calls[:terminate_instances].length > 0
end

