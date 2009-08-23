require File.expand_path('../../test_helper', __FILE__)

class BootstrapDeploymentTest < ActiveSupport::TestCase
  def setup
    Ec2.mode = :test
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
