require File.expand_path('../../test_helper', __FILE__)

class BootstrapDeploymentTest < ActiveSupport::TestCase
  def setup
    Ec2.mode = :test
    @instance   = Factory(:instance, :role => "mysql_master")
    @deployment = BootstrapDeployment.new :instance => @instance
  end 

  should "notify the instance of start" do
    @instance.expects(:bootstrapping!)
    @deployment.send(:notify_instance_of_start)
  end

  should "notify the instance of success" do
    @instance.expects(:bootstrapped!)
    @deployment.send(:notify_instance_of_success)
  end
end
