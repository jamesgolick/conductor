class InstancesController < ResourceController::Base
  belongs_to :environment

  create.flash { "Your instance(s) are being launched." }
  create.wants.html { redirect_to [@environment.application, @environment] }

  destroy.wants.html { redirect_to [@environment.application, @environment] }

  index.wants.js { render :partial => "environments/instance", :collection => @environment.instances }

  def deployments
    load_object
    @instance.deploy
    flash[:notice] = "Deploying"

    redirect_to @instance.environment
  end
end
