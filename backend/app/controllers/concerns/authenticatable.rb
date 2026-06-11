# JWT による認証を提供する concern。
# 認証が必要なコントローラで `before_action :authenticate_request` を呼ぶ。
# 認証 = 「誰か」の確認（認可は Pundit が担当。security-policy.md）。
module Authenticatable
  extend ActiveSupport::Concern

  included do
    attr_reader :current_user
  end

  private

  def authenticate_request
    payload = JsonWebToken.decode(bearer_token)
    @current_user = payload && User.find_by(id: payload[:user_id])
    render_unauthorized unless @current_user
  end

  def bearer_token
    header = request.headers["Authorization"]
    header.to_s.split(" ").last
  end

  def render_unauthorized
    render json: { error: { code: "unauthorized", message: "認証が必要です" } },
           status: :unauthorized
  end
end
