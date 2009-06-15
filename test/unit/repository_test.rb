require File.expand_path('../../test_helper', __FILE__)

class RepositoryTest < Test::Unit::TestCase
  def setup
    @repo_path = File.dirname(__FILE__) + '/../fixtures/test_repo'
    @clone_path = File.dirname(__FILE__) + '/../fixtures/cloned_repo'
    FileUtils.mkdir_p(@repo_path)
    `cd #{@repo_path} && git init && touch a_file && git add . && git commit -m"a commit"`
  end

  def teardown
    FileUtils.rm_r(@repo_path) if File.exist?(@repo_path)
    FileUtils.rm_r(@clone_path) if File.exist?(@clone_path)
  end

  context "Cloning a repository" do
    setup do
      @repo = Repository.new(@repo_path, @clone_path)
    end

    should "clone the repository to the specified dir" do
      assert File.directory?(@clone_path + "/.git")
      assert File.exist?(@clone_path + "/a_file")
    end
  end

  context "When the repository has already been cloned" do
    setup do
      @repo = Repository.new(@repo_path, @clone_path)
      `cd #{@repo_path} && touch another_file && git add . && git commit -m"commit"`
      @repo = Repository.new(@repo_path, @clone_path)
    end

    should "update the repo" do
      assert File.exist?(@clone_path + "/another_file")
    end
  end
end

