Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resources :boards, only: :show do
    resources :cards, only: :update
  end

  # Defines the root path route ("/")
  root to: redirect("/boards")
end
