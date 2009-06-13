class EnvironmentsController < ResourceController::Base
  belongs_to :application

  create.flash { "Your environment has been created." }
end
