require File.expand_path('../../test_helper', __FILE__)

class DnaTest < ActiveSupport::TestCase
  context "initializing the dna for an instance type" do
    setup do
      @dna = Dna.new("app")
    end

    should "automatically add that to the runlist" do
      assert_equal ["roles[app]"], @dna[:run_list]
    end
  end
end
