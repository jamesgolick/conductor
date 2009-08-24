class ChefDeployment < Deployment
  self.command = "
    source /etc/environment &&
      cd /var/chef &&
        git pull && 
          sudo env SSH_AUTH_SOCK=$SSH_AUTH_SOCK bash -c 'source /etc/environment && /opt/ruby-enterprise/bin/chef-solo -j /etc/chef/dna.json'"

  def run_commands
    put_dna
    super
  end

  protected
    def notify_instance_of_success
      instance.deployed!
    end

    def notify_instance_of_failure
      instance.deployment_failed!
    end

    def notify_instance_of_start
      instance.deploying!
    end

    def put_dna
      ssh.put instance.dna.to_json, "/etc/chef/dna.json"
    end
end

