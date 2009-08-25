require File.expand_path('../../test_helper', __FILE__)

class AddressTest < ActiveSupport::TestCase
  def setup
    Ec2.mode = :test
  end

  context "Creating a new address" do
    should "allocate an address via ec2" do
      @address = Address.create

      assert_equal Ec2.test_responses[:allocate_address], @address.address
    end
  end
end
