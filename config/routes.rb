ActionController::Routing::Routes.draw do |map|
  map.resources :applications, :has_many => :environments
  map.resources :environments, :has_many => :instances
end
