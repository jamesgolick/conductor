require File.expand_path('../../test_helper', __FILE__)

class DnaTest < ActiveSupport::TestCase
  context "initializing the dna for an instance type" do
    setup do
      CookbookRepository.any_instance.stubs(:clone).stubs(:pull)
      @repo = CookbookRepository.new("doesn't matter")
      @repo.stubs(:read).returns("some_attr 'a value'")
      @dna  = Dna.new("app", @repo)
    end

    should "automatically add that to the runlist" do
      assert_equal ["role[app]"], @dna[:run_list]
    end

    should "instance eval the attributes file" do
      assert_equal "a value", @dna.some_attr
    end
  end

  context "Accessing hash keys via method syntax" do
    setup do
      @dna = Dna.new("app", stub_everything(:read => ''))
      @dna.some_attribute "some value"
    end

    should "set that attribute" do
      assert_equal "some value", @dna.some_attribute
    end
  end
end
