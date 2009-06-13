Given /^that I've launched a (.+) instance in (.+)$/ do |instance_type, env_name|
  Factory(instance_type.to_sym, 
            :environment => Environment.find_by_name(env_name))
end

