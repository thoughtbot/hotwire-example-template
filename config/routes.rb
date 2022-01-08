Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :buildings, only: [:new, :create, :show]

  # Defines the root path route ("/")
  # root "articles#index"
  root to: redirect("/buildings/new")
end
