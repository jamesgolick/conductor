class DeploymentRunner
  attr_reader :instances, :logger

  def initialize(*instances)
    @instances = instances
    @logger    = DeploymentLogger.new(deployment_type, *instances)
    send_later :perform_deployment
  end

  def perform_deployment
    notify_instances(:start)
    handle_result ssh_session.execute
  end

  def ssh_session
    @ssh_session ||= create_ssh_session
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
      failed_hosts = result.failed_hosts.join(', ')

      if result.cancelled?
        logger.system_message "Deployment was cancelled because a command failed on [#{failed_hosts}]"
        notify_instances :cancelled
      else
        logger.system_message "Deployment failed on [#{failed_hosts}]."
        notify_instances :failure
      end
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
end

