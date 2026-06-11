class ApplicationController < ActionController::API
  include Pundit::Authorization
  include Authenticatable

  # 認可（Pundit）に失敗したら 403
  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  # リソースが見つからなければ 404
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  # 不正な状態遷移は 422
  rescue_from InvalidTransition do |e|
    render_error(e.code, e.message)
  end

  private

  # Pundit が参照するユーザー
  def pundit_user
    current_user
  end

  def render_error(code, message, status = :unprocessable_entity)
    render json: { error: { code:, message: } }, status:
  end

  def render_forbidden
    render_error("forbidden", "権限がありません", :forbidden)
  end

  def render_not_found
    render_error("not_found", "リソースが見つかりません", :not_found)
  end
end
