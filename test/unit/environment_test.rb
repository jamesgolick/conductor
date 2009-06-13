require File.dirname(__FILE__) + '/../test_helper'

class EnvironmentTest < Test::Unit::TestCase
  should_belong_to :application
  should_validate_presence_of :name
end
