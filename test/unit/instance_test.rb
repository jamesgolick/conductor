require File.dirname(__FILE__) + '/../test_helper'

class InstanceTest < Test::Unit::TestCase
  should_belong_to :environment
  should_validate_presence_of :size, :zone, :role
end
