Rails.application.routes.draw do
  root "app_shell#index"
  get "search/stream", to: "flights_stream#show", as: :flights_stream
  get "logs", to: "app_shell#logs", as: :app_logs
  get "settings", to: "app_shell#settings", as: :app_settings

  namespace :api do
    resources :commands, only: %i[create show]
    get "queries/:name", to: "queries#show", as: :query
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
