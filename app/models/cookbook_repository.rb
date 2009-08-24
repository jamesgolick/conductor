class CookbookRepository
  attr_reader :repo_location

  def initialize(repo_location)
    @repo_location = repo_location
    clone_exists? ? pull : clone
  end

  protected
    def clone_exists?
      File.directory?(clone_location + "/.git")
    end
    
    def pull
      `cd #{clone_location} && git pull`
    end

    def clone
      `git clone #{repo_location} #{clone_location}`
    end

    def clone_location
      "#{Rails.root}/cookbook-repo"
    end
end

