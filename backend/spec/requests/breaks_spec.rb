require "rails_helper"

RSpec.describe "Breaks", type: :request do
  let(:user) { create(:user) }
  let(:token) { JsonWebToken.encode({ user_id: user.id }) }
  let(:auth_headers) { { "Authorization" => "Bearer #{token}" } }

  describe "POST /attendances/:attendance_id/breaks （休憩開始）" do
    context "勤務中" do
      let(:attendance) do
        create(:attendance, user: user, work_date: Date.current, status: :working)
      end

      it "201 で休憩中になり openBreakId を返す" do
        post "/attendances/#{attendance.public_id}/breaks", headers: auth_headers

        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["status"]).to eq("on_break")
        expect(body["openBreakId"]).to start_with("brk_")
      end
    end

    it "退勤済みは 422" do
      attendance = create(:attendance, user: user, work_date: Date.current, status: :finished)
      post "/attendances/#{attendance.public_id}/breaks", headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]["code"]).to eq("already_clocked_out")
    end

    it "既に休憩中は 422" do
      attendance = create(:attendance, user: user, work_date: Date.current, status: :on_break)
      post "/attendances/#{attendance.public_id}/breaks", headers: auth_headers

      expect(JSON.parse(response.body)["error"]["code"]).to eq("already_on_break")
    end

    it "未認証は 401" do
      attendance = create(:attendance, user: user)
      post "/attendances/#{attendance.public_id}/breaks"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /attendances/:attendance_id/breaks/:id （休憩終了）" do
    it "200 で勤務中に戻る" do
      attendance = create(:attendance, user: user, work_date: Date.current, status: :on_break)
      brk = create(:attendance_break, attendance: attendance, started_at: 10.minutes.ago)

      patch "/attendances/#{attendance.public_id}/breaks/#{brk.public_id}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["status"]).to eq("working")
    end

    it "終了済みの休憩は 422" do
      attendance = create(:attendance, user: user, work_date: Date.current, status: :working)
      brk = create(:attendance_break, :finished, attendance: attendance)

      patch "/attendances/#{attendance.public_id}/breaks/#{brk.public_id}", headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]["code"]).to eq("not_on_break")
    end

    it "未認証は 401" do
      attendance = create(:attendance, user: user)
      brk = create(:attendance_break, attendance: attendance)
      patch "/attendances/#{attendance.public_id}/breaks/#{brk.public_id}"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
