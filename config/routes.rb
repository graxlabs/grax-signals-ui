Rails.application.routes.draw do
  get "home/index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  devise_for :users,
    controllers: { omniauth_callbacks: 'users/omniauth_callbacks' },
    skip: [:sessions, :registrations, :passwords] # Skip standard Devise routes

  # Override default Devise routes to handle sign in/out
  devise_scope :user do
    # Redirect users to Google sign-in
    get 'sign_in', to: 'home#index', as: :new_user_session

    # Sign out path
    delete 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end

  # Defines the root path route ("/")
  root "home#index"
  resources :scoring_runs, only: [:index, :show, :create]
  resources :leads, only: [:index, :show]
  resources :dictionary, only: [:index, :show]
end
