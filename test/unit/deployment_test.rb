require File.expand_path('../../test_helper', __FILE__)

class DeploymentTest < ActiveSupport::TestCase
  def setup
    Ec2.mode = :test
    Deployment.any_instance.stubs(:notify_instance_of_start)
    Deployment.any_instance.stubs(:notify_instance_of_failure)
    Deployment.any_instance.stubs(:notify_instance_of_success)
  end 

  context "Creating a deployment" do
    setup do
      @instance = Factory(:instance, :role => "mysql_master")
      Instance.any_instance.stubs(:connection_string).returns("james@myserver.com")
    end

    should "start an ssh session with the instance and run the command" do
      session_mock = mock
      session_mock.expects(:run).
        with(Deployment.command).
          returns(stub_everything)
      SshSession.expects(:new).with("james@myserver.com").returns(session_mock)

      @deployment = Deployment.new :instance => @instance
      @deployment.perform_deployment
    end

    should "store the log of the session" do
      SshSession.any_instance.stubs(:run).yields("the log").returns(CommandResult.new("", "the log", 0))
      Deployment.any_instance.stubs(:notify_instance)
      @deployment = Deployment.new :instance => @instance
      @deployment.perform_deployment

      assert_equal "the log", @deployment.log
    end

    should "store the exit code of the session" do
      SshSession.any_instance.stubs(:run).returns(CommandResult.new("", "the log", 127))
      @deployment = Deployment.new :instance => @instance
      @deployment.perform_deployment

      assert_equal 127, @deployment.exit_code
    end

    should "call #notify_instance_of_start during the deployment" do
      SshSession.any_instance.stubs(:run).returns(CommandResult.new("", "the log", 127))
      @deployment = Deployment.create :instance => @instance
      @deployment = Deployment.new :instance => @instance
      @deployment.expects(:notify_instance_of_start)
      @deployment.perform_deployment
    end

    should "call #notify_instance_of_success if the deployment is successful" do
      SshSession.any_instance.stubs(:run).returns(CommandResult.new("", "the log", 0))
      Deployment.any_instance.expects(:notify_instance_of_success)
      @deployment = Deployment.new :instance => @instance
      @deployment.perform_deployment
    end

    should "call #notify_instance_of_success if the deployment is successful" do
      SshSession.any_instance.stubs(:run).returns(CommandResult.new("", "the log", 127))
      Deployment.any_instance.expects(:notify_instance_of_failure)
      @deployment = Deployment.new :instance => @instance
      @deployment.perform_deployment
    end
  end

  should "be successful if the exit code is 0" do
    @deployment = Deployment.new :exit_code => 0
    assert @deployment.successful?
  end

  should "not be successful if the exit code is not 0" do
    @deployment = Deployment.new :exit_code => 127
    assert !@deployment.successful?
  end

  should "return the last line of the log" do
    @deployment = Deployment.new :log => "stuff\nand other stuff"
    assert_equal "and other stuff", @deployment.last_line_of_log
  end

  should "not raise if the log is nil" do
    @deployment = Deployment.new
    assert_equal "", @deployment.last_line_of_log
  end

  context "Creating a deployment with :dont_deploy => true" do
    should "not perform the deployment" do
      @deployment = Deployment.new :dont_deploy => true
      @deployment.expects(:send_later).with(:perform_deployment).never
      @deployment.save
    end
  end
end
