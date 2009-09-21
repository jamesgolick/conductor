class ChefDeploymentRunner < DeploymentRunner
  protected
    def deployment_type
      :chef
    end
end
