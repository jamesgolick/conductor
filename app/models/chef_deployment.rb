class ChefDeployment < Deployment
  self.command = "
    source /etc/environment &&
      cd /var/chef &&
        git pull && 
          /opt/ruby-enterprise/bin/chef-solo -j /etc/chef/dna.json"

  def run_commands
    put_dna
    super
  end

  protected
    def notify_instance
    end

    def put_dna
      ssh.put instance.dna.to_json, "/etc/chef/dna.json"
    end
end

