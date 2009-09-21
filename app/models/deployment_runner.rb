class DeploymentRunner
  attr_reader :instances, :logger

  def initialize(*instances)
    @instances = instances
    @logger    = DeploymentLogger.new(deployment_type, *instances)
  end

  def perform_deployment
    notify_instances(:start)
    handle_result ssh_session.execute
  end

  #def perform_deployment
  #  set_instance_states(:deploying)
  #  result = @session = SshSession.new(*instances.map(&:connection_string)) do
  #    put build_put_command
  #    run "cd /var/chef && git pull"
  #    run "/usr/bin/chef-solo -j /etc/chef/dna.json"
  #    before_command { |command| logger.system_message("Running command #{command}.") }
  #    on_data { |host, stream, data| logger.log(host, stream, data) }
  #  end.execute

  #  result.successful? ? log_success : log_failure(result)
  #end

  def ssh_session
    @ssh_session ||= SshSession.new {}
  end

  protected
    def deployment_type
      raise NotImplementedError, "Subclasses must implement #deployment_type"
    end

    def notify_instances(event)
      instances.each { |i| i.deployment_event(self, event) }
    end

    def handle_result(result)
      result.successful? ? handle_success(result) : handle_failure(result)
    end

    def handle_success(result)
      logger.system_message "Deployment ran successfully."
      notify_instances :successful
    end

    def handle_failure(result)
      logger.system_message "Deployment failed on one or more instances."
      notify_instances :failure
    end
end

