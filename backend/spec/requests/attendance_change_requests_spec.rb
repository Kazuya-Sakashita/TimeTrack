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

    it "status で絞り込める" do
      a1 = create(:attendance, user: user, work_date: Date.new(2026, 6, 1))
      a2 = create(:attendance, user: user, work_date: Date.new(2026, 6, 2))
      create(:attendance_change_request, user: user, attendance: a1, status: :pending)
      create(:attendance_change_request, user: user, attendance: a2, status: :approved)

      get "/attendance_change_requests", params: { status: "pending" }, headers: auth_headers

      body = JSON.parse(response.body)
      expect(body.size).to eq(1)
      expect(body.first["status"]).to eq("pending")
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

  describe "PATCH /attendance_change_requests/:id （承認・却下）" do
    let(:admin) { create(:user, :admin) }
    let(:admin_headers) { { "Authorization" => "Bearer #{JsonWebToken.encode({ user_id: admin.id })}" } }
    let(:target_attendance) do
      create(:attendance, user: user, work_date: Date.new(2026, 6, 12),
             clock_in_at: Time.zone.local(2026, 6, 12, 9, 30))
    end
    let(:change_request) do
      create(:attendance_change_request, user: user, attendance: target_attendance,
             proposed_clock_in_at: Time.zone.local(2026, 6, 12, 9, 0))
    end

    context "承認者（admin）" do
      it "承認すると 200・勤怠に反映される" do
        patch "/attendance_change_requests/#{change_request.public_id}",
              params: { status: "approved", comment: "確認しました" }, headers: admin_headers

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["status"]).to eq("approved")
        expect(target_attendance.reload.clock_in_at).to eq(Time.zone.local(2026, 6, 12, 9, 0))
      end

      it "却下すると 200・勤怠は変わらない" do
        patch "/attendance_change_requests/#{change_request.public_id}",
              params: { status: "rejected" }, headers: admin_headers

        expect(JSON.parse(response.body)["status"]).to eq("rejected")
        expect(target_attendance.reload.clock_in_at).to eq(Time.zone.local(2026, 6, 12, 9, 30))
      end

      it "申請中以外は 422" do
        change_request.update!(status: :approved)
        patch "/attendance_change_requests/#{change_request.public_id}",
              params: { status: "rejected" }, headers: admin_headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]["code"]).to eq("not_pending")
      end
    end

    context "権限なし" do
      it "申請者本人（従業員）は 403" do
        patch "/attendance_change_requests/#{change_request.public_id}",
              params: { status: "approved" }, headers: auth_headers
        expect(response).to have_http_status(:forbidden)
      end

      it "manager でも自分の申請は承認できず 403" do
        manager = create(:user, :manager)
        own = create(:attendance_change_request, user: manager)
        headers = { "Authorization" => "Bearer #{JsonWebToken.encode({ user_id: manager.id })}" }

        patch "/attendance_change_requests/#{own.public_id}",
              params: { status: "approved" }, headers: headers
        expect(response).to have_http_status(:forbidden)
      end

      it "未認証は 401" do
        patch "/attendance_change_requests/#{change_request.public_id}", params: { status: "approved" }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /attendance_change_requests/:id （取消）" do
    it "申請者本人が申請中の申請を取り消せる（204）" do
      req = create(:attendance_change_request, user: user, status: :pending)

      expect {
        delete "/attendance_change_requests/#{req.public_id}", headers: auth_headers
      }.to change(AttendanceChangeRequest, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "申請中以外は取り消せず 403" do
      req = create(:attendance_change_request, user: user, status: :approved)
      delete "/attendance_change_requests/#{req.public_id}", headers: auth_headers
      expect(response).to have_http_status(:forbidden)
    end

    it "他人の申請は取り消せず 403" do
      req = create(:attendance_change_request, user: create(:user), status: :pending)
      delete "/attendance_change_requests/#{req.public_id}", headers: auth_headers
      expect(response).to have_http_status(:forbidden)
    end

    it "未認証は 401" do
      req = create(:attendance_change_request, user: user)
      delete "/attendance_change_requests/#{req.public_id}"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
