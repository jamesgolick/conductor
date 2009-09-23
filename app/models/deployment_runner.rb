class DeploymentRunner
  attr_reader :instances, :logger, :notifier

  def initialize(*instances)
    @instances = instances
    @logger    = DeploymentLogger.new(deployment_type, *instances)
    @notifier  = InstanceNotifier.new(self, *instances)
  end

  def perform_deployment
    notifier.start
    handle_result ssh_session.execute
  end

  def ssh_session
    @ssh_session ||= create_ssh_session
  end

  protected
    def deployment_type
      raise NotImplementedError, "Subclasses must implement #deployment_type"
    end

    def handle_result(result)
      result.successful? ? handle_success(result) : handle_failure(result)
    end

    def handle_success(result)
      logger.system_message "Deployment ran successfully."
      notifier.successful
    end

    def handle_failure(result)
      logger.system_message failure_message(result)
      event = result.cancelled? ? :cancelled : :failure
      notifier.send(event, result.failed_hosts)
    end

    def create_ssh_session
      returning build_ssh_session do |s|
        s.before_command { |c| logger.system_message("Running command #{c}.") }
        s.on_data        { |host, stream, data| logger.log(host, stream, data) }
      end
    end

    def build_ssh_session
      raise NotImplementedError, "Implement #build_ssh_session in subclasses."
    end

    def failure_message(result)
      verb  = result.cancelled? ? "was cancelled" : "failed"
      hosts = result.failed_hosts.join(', ')
      "The deployment #{verb} because a command failed on [#{hosts}]."
    end
end

