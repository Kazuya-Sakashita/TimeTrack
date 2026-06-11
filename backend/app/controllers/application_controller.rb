class ApplicationController < ActionController::API
  include Pundit::Authorization
  include Authenticatable

  # 認可（Pundit）に失敗したら 403
  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

  private

  # Pundit が参照するユーザー
  def pundit_user
    current_user
  end

  def render_forbidden
    render json: { error: { code: "forbidden", message: "権限がありません" } },
           status: :forbidden
  end
end
