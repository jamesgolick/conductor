class DeploymentRunner
  attr_reader :instances, :logs

  def initialize(*instances)
    @instances = instances
  end

  def perform_deployment
    build_logs
  end

  protected
    def build_logs
      instances.inject({}) do |hash, instance|
        hash[instance] = instance.chef_logs.create
        hash
      end
    end
end

