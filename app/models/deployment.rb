class Deployment < ActiveRecord::Base
  class_inheritable_accessor :command

  belongs_to    :instance
  before_create :run_commands
  after_create  :notify_instance, :if => :successful?

  def successful?
    exit_code == 0
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

    def notify_instance
      raise NotImplementedError, "#notify_instnace needs to be implemented per subclass of Deployment"
    end
end
