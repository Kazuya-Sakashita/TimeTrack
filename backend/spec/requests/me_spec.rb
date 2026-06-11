require "rails_helper"

RSpec.describe "Me", type: :request do
  describe "GET /me" do
    let(:user) { create(:user, email: "me@example.com", name: "私 太郎") }
    let(:token) { JsonWebToken.encode({ user_id: user.id }) }

    context "有効なトークン" do
      it "200 でログイン中ユーザーを返す" do
        get "/me", headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["email"]).to eq("me@example.com")
        expect(body["id"]).to eq(user.public_id)
      end
    end

    context "トークンなし" do
      it "401 を返す" do
        get "/me"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "改ざん・不正なトークン" do
      it "401 を返す" do
        get "/me", headers: { "Authorization" => "Bearer invalid.token.value" }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
