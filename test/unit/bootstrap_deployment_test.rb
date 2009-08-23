require File.expand_path('../../test_helper', __FILE__)

class BootstrapDeploymentTest < ActiveSupport::TestCase
  def setup
    Ec2.mode = :test
  end 

  context "Creating a bootstrap deployment" do
    should "start an ssh session with the instance and run the command" do
      @instance    = Factory(:instance, :role => "mysql_master")
      Instance.any_instance.stubs(:connection_string).returns("james@myserver.com")

      session_mock = mock
      session_mock.expects(:run).with(BootstrapDeployment.command)
      SshSession.expects(:new).with("james@myserver.com").returns(session_mock)

      @deployment  = @instance.bootstrap_deployments.create
    end
  end
end
