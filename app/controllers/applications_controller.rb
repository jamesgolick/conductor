class ApplicationsController < ResourceController::Base
  create.flash "Your application has been created."
  create.wants.html { redirect_to application_environments_url(object) }
  update.wants.html { redirect_to application_environments_url(object) }
end
