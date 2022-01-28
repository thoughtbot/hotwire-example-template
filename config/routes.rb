Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :messages
  resources :searches, only: :index

  root to: redirect("/messages")
end
