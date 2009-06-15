class Repository
  attr_reader :repo_path, :clone_path

  def initialize(repo_path, clone_path)
    @repo_path  = repo_path
    @clone_path = clone_path
    clone_or_update
  end

  protected
    def clone_or_update
      File.directory?(clone_path) ? update : clone
    end

    def clone
      `git clone #{repo_path} #{clone_path}`
    end

    def update
      `cd #{clone_path} && git pull 2>1`
    end
end

