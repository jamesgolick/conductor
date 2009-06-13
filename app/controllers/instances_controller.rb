class InstancesController < ResourceController::Base
  belongs_to :environment

  create.flash { "Your instance(s) are being launched." }
end
