Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :messages, only: [:index, :new, :create]

  # Defines the root path route ("/")
  # root "articles#index"
  root to: redirect("/messages")
end
