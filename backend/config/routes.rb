Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # アプリ + DB の疎通確認（Walking Skeleton）
  get "health" => "health#show"

  # 認証
  post "auth/login" => "auth/sessions#create"
  delete "auth/logout" => "auth/sessions#destroy"

  # ログイン中ユーザー
  get "me" => "me#show"

  # 勤怠打刻
  post "attendances/clock-in" => "attendances#clock_in"

  # Defines the root path route ("/")
  # root "posts#index"
end
