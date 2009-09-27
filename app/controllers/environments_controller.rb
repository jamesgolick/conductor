class EnvironmentsController < ResourceController::Base
  belongs_to :application

  create.flash { "Your environment has been created." }

  def deployments
    load_object
    @environment.send_later :deploy

    flash[:notice] = "Deploying..."
    redirect_to @environment
  end
end
