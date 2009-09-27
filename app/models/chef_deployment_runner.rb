class ChefDeploymentRunner < DeploymentRunner
  protected
    def deployment_type
      :chef
    end

    def build_ssh_session
      put_arguments = dna.merge(:path => "/etc/chef/dna.json")
      SshSession.new(*instances.map(&:connection_string)) do
        put put_arguments
        run "/usr/local/bin/run_chef git@github.com:giraffesoft/conductor-cookbooks.git"
      end
    end

    def dna
      Hash[*instances.map { |i| [i.connection_string, i.dna.to_json] }.flatten]
    end
end
