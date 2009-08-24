require File.expand_path('../../test_helper', __FILE__)

class CookbookRepositoryTest < ActiveSupport::TestCase
  def setup
    Rails.backtrace_cleaner.remove_silencers! 
  end

  context "Initializing a cookbook repository" do
    should "clone the repository" do
      repo_location  = "git@github.com:giraffesoft/conductor-cookbooks.git"
      clone_location = "#{Rails.root}/cookbook-repo"
      CookbookRepository.any_instance.expects(:`).with("git clone #{repo_location} #{clone_location}")
      @repo = CookbookRepository.new("git@github.com:giraffesoft/conductor-cookbooks.git")
    end
  end

  context "When the repository already exists" do
    should "pull" do
      repo_location  = "git@github.com:giraffesoft/conductor-cookbooks.git"
      clone_location = "#{Rails.root}/cookbook-repo"
      File.stubs(:directory?).with(clone_location + "/.git").returns(true)
      CookbookRepository.any_instance.expects(:`).with("cd #{clone_location} && git pull")
      @repo = CookbookRepository.new("git@github.com:giraffesoft/conductor-cookbooks.git")
    end
  end
end
