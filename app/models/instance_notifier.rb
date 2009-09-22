class InstanceNotifier
  attr_reader :runner, :instances

  def initialize(runner, *instances)
    @runner    = runner
    @instances = instances
  end

  def successful
    notify_all :successful
  end

  def start
    notify_all :start
  end

  protected
    def notify_all(event)
      instances.each { |i| i.deployment_event(runner, event) }
    end
end

