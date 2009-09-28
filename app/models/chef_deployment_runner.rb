class ChefDeploymentRunner < DeploymentRunner
  protected
    def deployment_type
      :chef
    end

    def build_ssh_session
      put_arguments = dna.merge(:path => "/etc/chef/dna.json")
      cookbook_url  = instances.first.environment.application.cookbook_clone_url
      SshSession.new(*instances.map(&:connection_string)) do
        put put_arguments
        # TODO: this is ugly
        run "/usr/local/bin/run_chef #{cookbook_url}"
      end
    end

    def dna
      Hash[*instances.map { |i| [i.connection_string, i.dna.to_json] }.flatten]
    end
end
