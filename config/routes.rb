Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :invitation_codes, only: :show

  # Defines the root path route ("/")
  # root "articles#index"
  root to: redirect("/invitation_codes/abc123")
end
