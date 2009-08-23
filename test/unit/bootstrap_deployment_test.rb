require File.expand_path('../../test_helper', __FILE__)

class BootstrapDeploymentTest < ActiveSupport::TestCase
  def setup
    Ec2.mode = :test
  end 

  context "Creating a bootstrap deployment" do
    setup do
      @instance    = Factory(:instance, :role => "mysql_master")
      Instance.any_instance.stubs(:connection_string).returns("james@myserver.com")
    end

    should "start an ssh session with the instance and run the command" do
      session_mock = mock
      session_mock.expects(:run).
        with(BootstrapDeployment.command).
          returns(stub_everything)
      SshSession.expects(:new).with("james@myserver.com").returns(session_mock)

      @deployment  = @instance.bootstrap_deployments.create
    end

    should "store the log of the session" do
      SshSession.any_instance.stubs(:run).returns(CommandResult.new("", "the log", 0))
      @deployment  = @instance.bootstrap_deployments.create

      assert_equal "the log", @deployment.log
    end

    should "store the exit code of the session" do
      SshSession.any_instance.stubs(:run).returns(CommandResult.new("", "the log", 127))
      @deployment  = @instance.bootstrap_deployments.create

      assert_equal 127, @deployment.exit_code
    end
  end

  should "be successful if the exit code is 0" do
    @deployment = BootstrapDeployment.new :exit_code => 0
    assert @deployment.successful?
  end

  should "not be successful if the exit code is not 0" do
    @deployment = BootstrapDeployment.new :exit_code => 127
    assert !@deployment.successful?
  end

  context "If the deployment is successful" do
    should "notify the instance that it has been bootstrapped" do
      @deployment = BootstrapDeployment.new :exit_code => 0
      @deployment.stubs(:run_commands)
      @deployment.stubs(:successful).returns(true)
      @deployment.stubs(:instance).returns(mock(:bootstrapped! => nil))
      @deployment.save
    end
  end
end
