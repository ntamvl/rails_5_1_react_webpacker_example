Rails.application.routes.draw do
  root 'pages#home', as: :root

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
end
