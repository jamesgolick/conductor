require 'test_helper'

class DeploymentRunnerTest < ActiveSupport::TestCase
  def setup
    Ec2.mode = :test
    DeploymentRunner.any_instance.stubs(:deployment_type).returns(:chef)
    @instance = Factory(:mysql_master)
    @runner   = DeploymentRunner.new(@instance)
  end

  context "Creating a deployment on one instance" do
    should "create a deployment logger" do
      assert_equal [@instance], @runner.logger.instances
      assert_equal :chef, @runner.logger.log_type
    end
  end

  context "Running a deployment" do
    should "notify the instances" do
      @instance.expects(:deployment_event).with(@runner, :start)
      @runner.perform_deployment
    end
  end
end
