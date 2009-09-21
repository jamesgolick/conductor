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
    setup do
      @runner.stubs(:build_ssh_session).returns(SshSession.new {})
    end

    should "run the deployment" do
      @instance.expects(:deployment_event).with(@runner, :start)
      @runner.ssh_session.expects(:execute).returns(mock(:successful? => true))
      @instance.expects(:deployment_event).with(@runner, :successful)
      @runner.perform_deployment
    end

    should "notify the instances if one fails" do
      @instance.expects(:deployment_event).with(@runner, :start)
      proxy_mock = stub(:cancelled?   => false, 
                        :successful?  => false,
                        :failed_hosts => ["failsauce.com"])
      @runner.ssh_session.expects(:execute).returns(proxy_mock)
      @instance.expects(:deployment_event).with(@runner, :failure)
      @runner.perform_deployment
    end

    should "notify the instance if the deployment is cancelled" do
      @instance.expects(:deployment_event).with(@runner, :start)
      proxy_mock = stub(:cancelled?   => true, 
                        :successful?  => false,
                        :failed_hosts => ["whatever.com"])
      @runner.ssh_session.expects(:execute).returns(proxy_mock)
      @instance.expects(:deployment_event).with(@runner, :cancelled)
      @runner.perform_deployment
    end
  end

  context "The ssh session" do
    should "call #build_ssh_session, which should be impld by the subclass" do
      @runner.expects(:build_ssh_session).returns(stub_everything)
      @runner.ssh_session
    end
  end
end
