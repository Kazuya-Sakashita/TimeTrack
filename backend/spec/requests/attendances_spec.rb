require "rails_helper"

RSpec.describe "Attendances", type: :request do
  let(:user) { create(:user) }
  let(:token) { JsonWebToken.encode({ user_id: user.id }) }
  let(:auth_headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /attendances" do
    context "認証済み" do
      before do
        create(:attendance, user: user, work_date: Date.new(2026, 6, 10))
        create(:attendance, user: user, work_date: Date.new(2026, 6, 11))
        create(:attendance, user: create(:user), work_date: Date.new(2026, 6, 11))
      end

      it "自分の勤怠のみを新しい日付順で返す" do
        get "/attendances", headers: auth_headers

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["attendances"].size).to eq(2)
        expect(body["attendances"].map { |a| a["workDate"] }).to eq(["2026-06-11", "2026-06-10"])
      end

      it "ページングする" do
        get "/attendances", params: { page: 1, perPage: 1 }, headers: auth_headers

        body = JSON.parse(response.body)
        expect(body["attendances"].size).to eq(1)
        expect(body["pagination"]).to include("total" => 2, "totalPages" => 2)
      end
    end

    it "未認証は 401" do
      get "/attendances"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /attendances/:id" do
    it "自分の勤怠を返す" do
      attendance = create(:attendance, user: user)
      get "/attendances/#{attendance.public_id}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["id"]).to eq(attendance.public_id)
    end

    it "他人の勤怠は 404" do
      other = create(:attendance, user: create(:user))
      get "/attendances/#{other.public_id}", headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end

    it "未認証は 401" do
      attendance = create(:attendance, user: user)
      get "/attendances/#{attendance.public_id}"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /attendances （出勤）" do
    it "201 で出勤記録を作成する" do
      post "/attendances", headers: auth_headers

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["id"]).to start_with("att_")
      expect(body["status"]).to eq("working")
      expect(body["workDate"]).to eq(Date.current.iso8601)
    end

    it "本日2回目は 422" do
      create(:attendance, user: user, work_date: Date.current)
      post "/attendances", headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]["code"]).to eq("already_clocked_in")
    end

    it "未認証は 401" do
      post "/attendances"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /attendances/:id （退勤）" do
    it "200 で退勤済み・勤務時間を返す" do
      attendance = create(:attendance, user: user, work_date: Date.current,
                          clock_in_at: 8.hours.ago, status: :working)
      patch "/attendances/#{attendance.public_id}",
            params: { status: "finished" }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("finished")
      expect(body["workMinutes"]).to be_within(2).of(480)
    end

    it "既に退勤済みは 422" do
      attendance = create(:attendance, user: user, work_date: Date.current,
                          clock_in_at: 8.hours.ago, clock_out_at: 1.hour.ago, status: :finished)
      patch "/attendances/#{attendance.public_id}",
            params: { status: "finished" }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]["code"]).to eq("already_clocked_out")
    end

    it "存在しない勤怠は 404" do
      patch "/attendances/att_nonexistent",
            params: { status: "finished" }, headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end

    it "未認証は 401" do
      attendance = create(:attendance, user: user)
      patch "/attendances/#{attendance.public_id}", params: { status: "finished" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
