module Auth
  class SessionsController < ApplicationController
    before_action :authenticate_request, only: :destroy

    # POST /auth/login
    def create
      return render_validation_error if login_params[:email].blank? || login_params[:password].blank?

      user = User.find_by(email: login_params[:email].to_s.strip.downcase)

      if user&.authenticate(login_params[:password])
        token = JsonWebToken.encode({ user_id: user.id })
        render json: { token:, user: UserSerializer.call(user) }, status: :created
      else
        render json: { error: { code: "invalid_credentials",
                                message: "メールアドレスまたはパスワードが正しくありません" } },
               status: :unauthorized
      end
    end

    # DELETE /auth/logout
    # ステートレス JWT のためサーバ側は何もしない。クライアントがトークンを破棄する。
    def destroy
      head :no_content
    end

    private

    def login_params
      params.permit(:email, :password)
    end

    def render_validation_error
      render json: { error: { code: "validation_error",
                              message: "email と password は必須です" } },
             status: :unprocessable_entity
    end
  end
end
