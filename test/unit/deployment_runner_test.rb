require 'test_helper'

class DeploymentRunnerTest < ActiveSupport::TestCase
  def setup
    DeploymentRunner.any_instance.stubs(:deployment_type).returns(:chef)
    Ec2.mode         = :test
    @successful      = Factory(:running_instance)
    @failure         = Factory(:running_instance, :dns_name => "failsauce.com")
    @runner          = DeploymentRunner.new(@successful, @failure)
    @runner.instance_variable_set(:@notifier, stub_everything)
    @runner.stubs(:build_ssh_session).returns(SshSession.new {})
  end

  should "create a deployment logger" do
    assert_equal @runner.instances, @runner.logger.instances
    assert_equal :chef, @runner.logger.log_type
  end

  should "create an instance notifier" do
    @runner = DeploymentRunner.new(@successful, @failure)
    assert_equal @runner.instances, @runner.notifier.instances
    assert_equal @runner, @runner.notifier.runner
  end

  should "run the deployment" do
    @runner.notifier.expects(:start)
    @runner.notifier.expects(:successful)
    @runner.ssh_session.expects(:execute).returns(mock(:successful? => true))
    @runner.perform_deployment
  end

  should "notify the instances if one fails" do
    proxy_mock = stub(:cancelled?   => false, 
                      :successful?  => false,
                      :failed_hosts => ["failsauce.com"])
    @runner.notifier.expects(:failure).with(["failsauce.com"])
    @runner.ssh_session.expects(:execute).returns(proxy_mock)
    @runner.perform_deployment
  end

  should "notify the instances if the deployment is cancelled" do
    proxy_mock = stub(:cancelled?   => true, 
                      :successful?  => false,
                      :failed_hosts => ["failsauce.com"])
    @runner.ssh_session.expects(:execute).returns(proxy_mock)
    @runner.notifier.expects(:cancelled).with(["failsauce.com"])
    @runner.perform_deployment
  end

  context "The ssh session" do
    should "call #build_ssh_session, which should be impld by the subclass" do
      @runner.expects(:build_ssh_session).returns(stub_everything)
      @runner.ssh_session
    end
  end
end
