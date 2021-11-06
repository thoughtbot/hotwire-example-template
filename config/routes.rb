Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resources :sessions, only: [:new, :create]
  resources :users, only: :index do
    resources :messages, only: [:index, :create]
  end

  # Defines the root path route ("/")
  root to: redirect("/sessions/new")
end
