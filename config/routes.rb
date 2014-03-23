Spree::Core::Engine.routes.draw do

  namespace :admin do
    resource :drop_ship_settings
    resources :shipments
    resources :suppliers
  end

  resources :suppliers, only: [:create, :new]

end
