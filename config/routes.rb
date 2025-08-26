Rails.application.routes.draw do
  devise_for :users
  get "documents/index"
  get "documents/show"
  get "documents/create"
  get "documents/upload"
  get "chat/index"
  get "chat/analyze"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # NDL Platform routes
  root "chat#index"
  get "chat", to: "chat#index", as: :chat

  resources :documents, only: [:create, :show, :index]
  resources :hypotheses, only: [:show, :index, :destroy]
  resources :analyses, only: [:show, :index, :destroy]

  # Analysis workflow
  post "analyze", to: "chat#analyze"
  post "select_insight", to: "chat#select_insight"

  # Conversations (handled in chat controller)
  post "continue_conversation", to: "chat#continue_conversation"
  get "conversation_suggestions", to: "chat#conversation_suggestions"

  # File uploads
  post "upload", to: "documents#upload"
end
