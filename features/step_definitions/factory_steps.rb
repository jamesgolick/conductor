Given /^that I've created an? ([^\"]*) called "([^\"]*)"$/ do |model, name|
  Factory(model.to_sym, :name => name)
end
