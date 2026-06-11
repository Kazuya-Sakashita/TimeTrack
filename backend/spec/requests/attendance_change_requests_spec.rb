require "rails_helper"

RSpec.describe "AttendanceChangeRequests", type: :request do
  let(:user) { create(:user) }
  let(:token) { JsonWebToken.encode({ user_id: user.id }) }
  let(:auth_headers) { { "Authorization" => "Bearer #{token}" } }
  let(:attendance) { create(:attendance, user: user) }

  describe "POST /attendance_change_requests" do
    let(:valid_params) do
      {
        attendanceId: attendance.public_id,
        proposedClockInAt: "2026-06-12T09:00:00+09:00",
        reason: "打刻し忘れたため",
      }
    end

    it "201 で申請を作成する" do
      post "/attendance_change_requests", params: valid_params, headers: auth_headers

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["id"]).to start_with("acr_")
      expect(body["attendanceId"]).to eq(attendance.public_id)
      expect(body["status"]).to eq("pending")
    end

    it "理由が無いと 422" do
      post "/attendance_change_requests",
           params: valid_params.merge(reason: ""), headers: auth_headers
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "修正後の時刻が無いと 422" do
      post "/attendance_change_requests",
           params: { attendanceId: attendance.public_id, reason: "x" }, headers: auth_headers
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "他人の勤怠を対象にすると 404" do
      others = create(:attendance, user: create(:user))
      post "/attendance_change_requests",
           params: valid_params.merge(attendanceId: others.public_id), headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end

    it "未認証は 401" do
      post "/attendance_change_requests", params: valid_params
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /attendance_change_requests" do
    it "自分の申請のみを返す" do
      create(:attendance_change_request, user: user)
      create(:attendance_change_request, user: create(:user)) # 他人

      get "/attendance_change_requests", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(1)
    end

    it "管理者は全件を返す" do
      admin = create(:user, :admin)
      admin_token = JsonWebToken.encode({ user_id: admin.id })
      create(:attendance_change_request, user: user)
      create(:attendance_change_request, user: create(:user))

      get "/attendance_change_requests", headers: { "Authorization" => "Bearer #{admin_token}" }

      expect(JSON.parse(response.body).size).to eq(2)
    end
  end

  describe "GET /attendance_change_requests/:id" do
    it "自分の申請を返す" do
      req = create(:attendance_change_request, user: user)
      get "/attendance_change_requests/#{req.public_id}", headers: auth_headers
      expect(response).to have_http_status(:ok)
    end

    it "他人の申請は 403" do
      req = create(:attendance_change_request, user: create(:user))
      get "/attendance_change_requests/#{req.public_id}", headers: auth_headers
      expect(response).to have_http_status(:forbidden)
    end
  end
end
