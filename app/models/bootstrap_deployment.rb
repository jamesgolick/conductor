class BootstrapDeployment < Deployment
  class << self
    def command
      "apt-get install git-core && 
        git clone git@github.com/FetLife/fetlife-systems.git /var/chef &&
          /var/chef/bootstrap/bootstrap.sh"
    end
  end

  belongs_to    :instance
  before_create :run_commands

  protected
    def run_commands
      result   = ssh.run(self.class.command)
      self.log = result.log
    end

    def ssh
      @ssh ||= SshSession.new(instance.connection_string)
    end
end

