Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :addresses, only: [:new, :create, :show]

  # Defines the root path route ("/")
  # root "articles#index"
  root to: redirect("/addresses/new")
end
