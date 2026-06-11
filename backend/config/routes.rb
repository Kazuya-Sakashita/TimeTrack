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

  # 勤怠（リソース中心。出勤=create / 退勤=update / 休憩=breaks サブリソース）
  resources :attendances, only: %i[index show create update] do
    resources :breaks, only: %i[create update]
  end

  # 勤怠修正申請（承認/却下=update は Slice 7 で追加）
  resources :attendance_change_requests, only: %i[index show create]

  # Defines the root path route ("/")
  # root "posts#index"
end
