class InstancesController < ResourceController::Base
  belongs_to :environment

  create.flash { "Your instance(s) are being launched." }
  create.wants.html { redirect_to [@environment.application, @environment] }

  destroy.wants.html { redirect_to [@environment.application, @environment] }

  def deployments
    load_object
    @instance.send_later :start_deployment
    flash[:notice] = "Deploying"

    redirect_to @instance.environment
  end
end
