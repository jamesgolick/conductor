class Deployment < ActiveRecord::Base
  class_inheritable_accessor :command

  belongs_to    :instance
  after_create  :launch_deployment_job

  def successful?
    exit_code == 0
  end

  def perform_deployment
    notify_instance_of_start
    run_commands
    successful? ? notify_instance_of_success : notify_instance_of_failure
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

    def notify_instance_of_success
      raise NotImplementedError, "#notify_instance_of_success needs to be implemented per subclass of Deployment"
    end

    def notify_instance_of_start
      raise NotImplementedError, "#notify_instance_of_start needs to be implemented per subclass of Deployment"
    end

    def notify_instance_of_failure
      raise NotImplementedError, "#notify_instance_of_start needs to be implemented per subclass of Deployment"
    end

    def launch_deployment_job
      send_later :perform_deployment
    end
end
