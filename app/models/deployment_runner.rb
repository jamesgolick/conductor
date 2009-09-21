class DeploymentRunner
  attr_reader :instances, :logger

  def initialize(*instances)
    @instances = instances
    @logger    = DeploymentLogger.new(:chef, *instances)
  end

  def perform_deployment
    set_instance_states(:deploying)
    result = @session = SshSession.new(*instances.map(&:connection_string)) do
      put build_put_command
      run "cd /var/chef && git pull"
      run "/usr/bin/chef-solo -j /etc/chef/dna.json"
      before_command { |command| logger.system_message("Running command #{command}.") }
      on_data { |host, stream, data| logger.log(host, stream, data) }
    end.execute

    result.successful? ? log_success : log_failure(result)
  end

  protected
    def build_logs
      instances.inject({}) do |hash, instance|
        hash[instance] = instance.chef_logs.create
        hash
      end
    end

    def set_instance_states(state)
      instances.each { |i| i.update_attributes :state => state.to_s }
    end
end

