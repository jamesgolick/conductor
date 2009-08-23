class BootstrapDeployment < Deployment
  class << self
    def command
      "apt-get update &&
        apt-get install -y git-core && 
      echo '|1|sv3Od6rY/siudwEpT+g2xn7YnsU=|8Rtg7HTzZS0UmR2NHzALVgQdn2A= ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
            |1|bCSVbXPailzmrTScHcmJkv56zxI=|zJu/QV7pkexhJorVEzrNXnY9UBk= ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==' >> ~/.ssh/known_hosts && 
          if [ -d /var/chef ]; then
            cd /var/chef/bootstrap && git pull
          else
            git clone git@github.com:giraffesoft/conductor-cookbooks.git /var/chef
          fi &&
             /var/chef/bootstrap/bootstrap.sh
            "
    end
  end

  belongs_to    :instance
  before_create :run_commands

  def successful?
    exit_code == 0
  end

  protected
    def run_commands
      result         = ssh.run(self.class.command)
      self.log       = result.log
      self.exit_code = result.exit_code
    end

    def ssh
      @ssh ||= SshSession.new(instance.connection_string)
    end
end

