Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :mentions, only: :index
  resources :messages
  resources :users

  # Defines the root path route ("/")
  root to: redirect("/messages/new")
end
