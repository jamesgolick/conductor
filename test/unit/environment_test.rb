require File.dirname(__FILE__) + '/../test_helper'

class EnvironmentTest < Test::Unit::TestCase
  should_belong_to :application
  should_have_many :instances
  should_validate_presence_of :name

  context "When a database server has been created" do
    setup do
      @instance = Factory(:mysql_master)
    end

    should "be has_database_server?" do
      assert @instance.environment.has_database_server?
    end
  end

  context "When a database server has not been created" do
    setup do
      @environment = Factory(:environment)
    end

    should "not be has_database_server?" do
      assert !@environment.has_database_server?
    end
  end
end
