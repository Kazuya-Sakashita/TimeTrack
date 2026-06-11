require "rails_helper"

RSpec.describe "Auth::Sessions", type: :request do
  describe "POST /auth/login" do
    let!(:user) { create(:user, email: "admin@example.com", password: "password123") }

    context "正しい資格情報" do
      it "201 と JWT・ユーザー情報を返す" do
        post "/auth/login", params: { email: "admin@example.com", password: "password123" }

        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["token"]).to be_present
        expect(body["user"]["email"]).to eq("admin@example.com")
      end

      it "内部 id を漏らさず public_id を id として返す" do
        post "/auth/login", params: { email: "admin@example.com", password: "password123" }

        body = JSON.parse(response.body)
        expect(body["user"]["id"]).to start_with("usr_")
        expect(body["user"]).not_to have_key("password_digest")
      end

      it "発行された JWT で /me にアクセスできる" do
        post "/auth/login", params: { email: "admin@example.com", password: "password123" }
        token = JSON.parse(response.body)["token"]

        get "/me", headers: { "Authorization" => "Bearer #{token}" }
        expect(response).to have_http_status(:ok)
      end
    end

    context "パスワードが不正" do
      it "401 を返す" do
        post "/auth/login", params: { email: "admin@example.com", password: "wrong" }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]["code"]).to eq("invalid_credentials")
      end
    end

    context "存在しないメール" do
      it "401 を返す" do
        post "/auth/login", params: { email: "none@example.com", password: "password123" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "必須項目が欠落" do
      it "422 を返す" do
        post "/auth/login", params: { email: "admin@example.com" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]["code"]).to eq("validation_error")
      end
    end
  end

  describe "DELETE /auth/logout" do
    let(:user) { create(:user) }
    let(:token) { JsonWebToken.encode({ user_id: user.id }) }

    it "認証済みなら 204" do
      delete "/auth/logout", headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to have_http_status(:no_content)
    end

    it "未認証なら 401" do
      delete "/auth/logout"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
