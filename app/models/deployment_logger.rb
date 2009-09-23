class DeploymentLogger
  attr_reader :log_type, :instances, :logs

  def initialize(log_type, *instances)
    @log_type  = log_type
    @instances = instances
    init_logs
  end

  def log(host, stream, data)
    log_for(host).append(build_line(stream, data))
  end

  def system_message(message)
    logs.values.each do |l|
      l.append build_line(:system, message)
    end
  end

  protected
    def init_logs
      @logs = Hash[*instances.map { |i| [i, create_log(i)] }.flatten]
    end

    def create_log(instance)
      instance.send(:"#{log_type}_logs").create
    end

    def build_line(stream, data)
      "[#{stream.to_s.upcase}]: #{data}#{"\n" unless data.ends_with?("\n")}"
    end

    def log_for(host)
      logs[instances.detect { |i| i.dns_name == host }]
    end
end

