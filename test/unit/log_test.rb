require File.expand_path('../../test_helper', __FILE__)

class LogTest < ActiveSupport::TestCase
  def setup
    Ec2.mode = :test
    Log.any_instance.stubs(:notify_instance_of_start)
    Log.any_instance.stubs(:notify_instance_of_failure)
    Log.any_instance.stubs(:notify_instance_of_success)
  end 

  context "Creating a deployment" do
    setup do
      @instance = Factory(:instance, :role => "mysql_master")
      Instance.any_instance.stubs(:connection_string).returns("james@myserver.com")
    end

    should "start an ssh session with the instance and run the command" do
      session_mock = mock
      session_mock.expects(:run).
        with(Log.command).
          returns(stub_everything)
      Ssh.expects(:new).with("james@myserver.com").returns(session_mock)

      @deployment = Log.new :instance => @instance
      @deployment.perform_deployment
    end

    should "store the log of the session" do
      Ssh.any_instance.stubs(:run).yields("the log").returns(CommandResult.new("", "the log", 0))
      Log.any_instance.stubs(:notify_instance)
      @deployment = Log.new :instance => @instance
      @deployment.perform_deployment

      assert_equal "the log", @deployment.log
    end

    should "store the exit code of the session" do
      Ssh.any_instance.stubs(:run).returns(CommandResult.new("", "the log", 127))
      @deployment = Log.new :instance => @instance
      @deployment.perform_deployment

      assert_equal 127, @deployment.exit_code
    end

    should "call #notify_instance_of_start during the deployment" do
      Ssh.any_instance.stubs(:run).returns(CommandResult.new("", "the log", 127))
      @deployment = Log.create :instance => @instance
      @deployment = Log.new :instance => @instance
      @deployment.expects(:notify_instance_of_start)
      @deployment.perform_deployment
    end

    should "call #notify_instance_of_success if the deployment is successful" do
      Ssh.any_instance.stubs(:run).returns(CommandResult.new("", "the log", 0))
      Log.any_instance.expects(:notify_instance_of_success)
      @deployment = Log.new :instance => @instance
      @deployment.perform_deployment
    end

    should "call #notify_instance_of_success if the deployment is successful" do
      Ssh.any_instance.stubs(:run).returns(CommandResult.new("", "the log", 127))
      Log.any_instance.expects(:notify_instance_of_failure)
      @deployment = Log.new :instance => @instance
      @deployment.perform_deployment
    end
  end

  should "be successful if the exit code is 0" do
    @deployment = Log.new :exit_code => 0
    assert @deployment.successful?
  end

  should "not be successful if the exit code is not 0" do
    @deployment = Log.new :exit_code => 127
    assert !@deployment.successful?
  end

  should "return the last line of the log" do
    @deployment = Log.new :log => "stuff\nand other stuff"
    assert_equal "and other stuff", @deployment.last_line_of_log
  end

  should "not raise if the log is nil" do
    @deployment = Log.new
    assert_equal "", @deployment.last_line_of_log
  end

  context "Creating a deployment with :dont_deploy => true" do
    should "not perform the deployment" do
      @deployment = Log.new :dont_deploy => true
      @deployment.expects(:send_later).with(:perform_deployment).never
      @deployment.save
    end
  end
end
