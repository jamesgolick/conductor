require 'test_helper'

class InstanceNotifierTest < ActiveSupport::TestCase
  def setup
    Ec2.mode = :test
  end

  context "Notifying a set of instances" do
    setup do
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
  end

  protected
    def expect_all(event)
      @success.expects(:deployment_event).with(@deployer, event)
      @failure.expects(:deployment_event).with(@deployer, event)
    end
end
