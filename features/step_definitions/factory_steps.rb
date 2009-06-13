Given /^that I've created an application called "([^\"]*)"$/ do |name|
  Factory(:application, :name => name)
end
