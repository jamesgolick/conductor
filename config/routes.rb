ActionController::Routing::Routes.draw do |map|
  map.resources :applications, :has_many => :environments
  map.resources :environments, :member => {:deployments => :post} do |e|
    e.resources :instances, :member => {:deployments => :post}
  end
end
