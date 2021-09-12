Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :applicants, only: [:new, :create, :show, :edit, :update]

  # Defines the root path route ("/")
  # root "articles#index"
  root to: redirect("/applicants/new")
end
