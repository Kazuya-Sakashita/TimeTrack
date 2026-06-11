require "rails_helper"

RSpec.describe "Attendances", type: :request do
  let(:user) { create(:user) }
  let(:token) { JsonWebToken.encode({ user_id: user.id }) }
  let(:auth_headers) { { "Authorization" => "Bearer #{token}" } }

  describe "POST /attendances/clock-in" do
    context "認証済み・未打刻" do
      it "201 で出勤記録を返す" do
        post "/attendances/clock-in", headers: auth_headers

        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["id"]).to start_with("att_")
        expect(body["status"]).to eq("working")
        expect(body["clockInAt"]).to be_present
        expect(body["workDate"]).to eq(Date.current.iso8601)
      end

      it "本日の勤怠レコードが1件作られる" do
        expect {
          post "/attendances/clock-in", headers: auth_headers
        }.to change { user.attendances.count }.by(1)
      end
    end

    context "本日すでに出勤済み" do
      before { create(:attendance, user: user, work_date: Date.current) }

      it "422 を返す" do
        post "/attendances/clock-in", headers: auth_headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]["code"]).to eq("already_clocked_in")
      end
    end

    context "未認証" do
      it "401 を返す" do
        post "/attendances/clock-in"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
