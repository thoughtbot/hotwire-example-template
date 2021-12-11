Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :tasks, only: [:index, :new, :create, :update, :edit]

  # Defines the root path route ("/")
  # root "articles#index"
  root to: redirect("/tasks")
end
