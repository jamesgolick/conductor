require File.dirname(__FILE__) + '/../test_helper'

class ApplicationTest < Test::Unit::TestCase
  should_validate_presence_of :name, :clone_url
  should_have_many :environments
end
