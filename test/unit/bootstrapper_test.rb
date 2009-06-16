require File.expand_path('../../test_helper', __FILE__)

class BootstrapperTest < Test::Unit::TestCase
  def setup
    Ec2.mode  = :test
    @instance = Factory(:mysql_master)
  end

  context "Bootstrapping an instance" do
    should "call the bootstrap script with the correct parameters and set the instance to bootstrapped" do
      @bootstrapper = Bootstrapper.new(@instance)
      cmd = Rails.root + "/script/bootstrap #{@instance.application.name} #{@instance.application.cookbook_clone_url} #{@instance.dns_name}"
      @bootstrapper.expects(:`).with(cmd.to_s)
      @bootstrapper.bootstrap
      assert @instance.bootstrapped?
    end
  end
end
