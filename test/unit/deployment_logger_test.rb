require 'test_helper'

class DeploymentLoggerTest < ActiveSupport::TestCase
  def setup
    Ec2.mode = :test
  end

  context "Creating a deployment logger for a chef deployment" do
    setup do
      @instance = Factory(:mysql_master)
      @logger   = DeploymentLogger.new(:chef, @instance)
    end

    should "create an instance of chef_log for each instance" do
      assert_equal 1, @instance.chef_logs.count
    end

    should "create a hash for the chef_logs, keyed by instance" do
      assert_equal @instance.chef_logs.first, @logger.logs[@instance]
    end
  end
end
