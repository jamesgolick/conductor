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

  def cancelled(failed_hosts)
    notify_some(failed_hosts, :failure, :cancelled)
  end

  def failure(failed_hosts)
    notify_some(failed_hosts, :failure, :successful)
  end

  protected
    def notify_all(event)
      instances.each { |i| i.deployment_event(runner, event) }
    end

    def notify_some(hosts, included, not_included)
      instances.each do |i|
        event = hosts.include?(i.dns_name) ? included : not_included
        i.deployment_event(runner, event)
      end
    end
end

