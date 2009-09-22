require 'test_helper'

class InstanceNotifierTest < ActiveSupport::TestCase
  def setup
    Ec2.mode  = :test
    @success  = Factory(:running_instance)
    @failure  = Factory(:running_instance, :dns_name => "failsauce.com")
    @deployer = ChefDeploymentRunner.new
    @notifier = InstanceNotifier.new(@deployer, @success, @failure)
  end

  should "notify of start" do
    expect_all(:start)
    @notifier.start
  end

  should "notify of success" do
    expect_all(:successful)
    @notifier.successful
  end

  should "notify of cancellation" do
    @failure.expects(:deployment_event).with(@deployer, :failure)
    @success.expects(:deployment_event).with(@deployer, :cancelled)
    @notifier.cancelled(["failsauce.com"])
  end

  should "notify of failure" do
    @failure.expects(:deployment_event).with(@deployer, :failure)
    @success.expects(:deployment_event).with(@deployer, :successful)
    @notifier.failure(["failsauce.com"])
  end

  protected
    def expect_all(event)
      @success.expects(:deployment_event).with(@deployer, event)
      @failure.expects(:deployment_event).with(@deployer, event)
    end
end
