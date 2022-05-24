Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resource :grid, only: :show

  # Defines the root path route ("/")
  root to: redirect("/grid")
end
