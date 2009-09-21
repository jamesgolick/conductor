class DeploymentLogger
  attr_reader :log_type, :instances, :logs

  def initialize(log_type, *instances)
    @log_type  = log_type
    @instances = instances
    init_logs
  end

  protected
    def init_logs
      @logs = Hash[*instances.map { |i| [i, create_log(i)] }.flatten]
    end

    def create_log(instance)
      instance.send(:"#{log_type}_logs").create
    end
end

