require File.expand_path('../../test_helper', __FILE__)

class ChefDeploymentTest < ActiveSupport::TestCase
  def setup
    Ec2.mode = :test
    CookbookRepository.any_instance.stubs(:clone).stubs(:pull)
    CookbookRepository.any_instance.stubs(:read).returns("")
  end

  context "Creating a chef deployment" do
    should "create and upload DNA for that instance" do
      @instance   = Factory(:instance, :role => "mysql_master")
      @deployment = ChefDeployment.new :instance => @instance
      @deployment.send(:ssh).expects(:put).with(@instance.dna.to_json, "/etc/chef/dna.json")
      @deployment.send(:ssh).stubs(:run).returns(CommandResult.new("whatever", "", 0))
      @deployment.save
    end
  end
end
