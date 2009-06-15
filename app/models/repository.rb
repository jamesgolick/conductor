class Repository
  attr_reader :repo_path, :clone_path

  def initialize(repo_path, clone_path)
    @repo_path  = repo_path
    @clone_path = clone_path
    clone
  end

  protected
    def clone
      `git clone #{repo_path} #{clone_path}`
    end
end

