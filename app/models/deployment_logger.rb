class DeploymentLogger
  attr_reader :log_type, :instances, :logs

  def initialize(log_type, *instances)
    @log_type  = log_type
    @instances = instances
    init_logs
  end

  def log(host, stream, data)
    log      = log_for(host)
    new_log = [log.log, build_line(stream, data)].join
    log.update_attributes :log => new_log
  end

  protected
    def init_logs
      @logs = Hash[*instances.map { |i| [i, create_log(i)] }.flatten]
    end

    def create_log(instance)
      instance.send(:"#{log_type}_logs").create
    end

    def build_line(stream, data)
      "[#{stream.to_s.upcase}]: #{data}"
    end

    def log_for(host)
      logs[instances.detect { |i| i.dns_name == host }]
    end
end

