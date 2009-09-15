require 'test_helper'

class DeploymentRunnerTest < ActiveSupport::TestCase
  def setup
    Ec2.mode = :test
  end

  context "Running a deployment on one instance" do
    setup do
      @instance = Factory(:mysql_master)
      @runner   = DeploymentRunner.new(@instance)
    end

    should "create a chef log for that instance" do
      @runner.perform_deployment
      assert_equal 1, @instance.chef_logs.count
    end
  end
end
