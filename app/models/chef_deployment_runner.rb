class ChefDeploymentRunner < DeploymentRunner
  protected
    def deployment_type
      :chef
    end

    def build_ssh_session
      put_arguments = dna.merge(:path => "/etc/chef/dna.json")
      SshSession.new(*instances.map(&:connection_string)) do
        run "if [ -d /var/chef ]; then
          cd /var/chef && git pull
        else
          git clone git@github.com:giraffesoft/conductor-cookbooks.git /var/chef
        fi"
        put put_arguments
        run "source /etc/environment &&
              /opt/ruby-enterprise/bin/chef-solo -j /etc/chef/dna.json"
      end
    end

    def dna
      Hash[*instances.map { |i| [i.connection_string, i.dna.to_json] }.flatten]
    end
end
