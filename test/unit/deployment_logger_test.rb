require 'test_helper'

class DeploymentLoggerTest < ActiveSupport::TestCase
  def setup
    Ec2.mode = :test
  end

  context "Logging a chef deployment" do
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

    should "log to the appropriate chef_log instance (and save)" do
      @logger.log(@instance.dns_name, :stdout, "Some awesome STDOUT data.")
      chef_log = @instance.chef_logs.reload
      assert_equal "[STDOUT]: Some awesome STDOUT data.", chef_log.first.log
    end

    should "log to all instances when there's a system message" do
      @logger.system_message("Running command ls -la")
      chef_log = @instance.chef_logs.reload
      assert_equal "[SYSTEM]: Running command ls -la", chef_log.first.log
    end
  end
end
