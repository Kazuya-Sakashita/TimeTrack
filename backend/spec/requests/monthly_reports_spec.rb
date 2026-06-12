require "rails_helper"

RSpec.describe "MonthlyReports", type: :request do
  let(:user) { create(:user) }
  let(:token) { JsonWebToken.encode({ user_id: user.id }) }
  let(:auth_headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /monthly_reports/:month" do
    context "認証済み" do
      before do
        # 6/1: 9:00-18:00 休憩60分 → 勤務480分・残業0
        a1 = create(:attendance, user: user, work_date: Date.new(2026, 6, 1),
                    clock_in_at: Time.zone.local(2026, 6, 1, 9, 0),
                    clock_out_at: Time.zone.local(2026, 6, 1, 18, 0), status: :finished)
        create(:attendance_break, attendance: a1,
               started_at: Time.zone.local(2026, 6, 1, 12, 0),
               ended_at: Time.zone.local(2026, 6, 1, 13, 0))
        # 6/2: 9:00-19:00 休憩なし → 勤務600分・残業120分
        create(:attendance, user: user, work_date: Date.new(2026, 6, 2),
               clock_in_at: Time.zone.local(2026, 6, 2, 9, 0),
               clock_out_at: Time.zone.local(2026, 6, 2, 19, 0), status: :finished)
        # 別月（集計対象外）
        create(:attendance, user: user, work_date: Date.new(2026, 5, 20))
      end

      it "当月の集計を返す" do
        get "/monthly_reports/2026-06", headers: auth_headers

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["month"]).to eq("2026-06")
        expect(body["workingDays"]).to eq(2)
        expect(body["totalWorkMinutes"]).to eq(480 + 600)
        expect(body["totalBreakMinutes"]).to eq(60)
        expect(body["overtimeMinutes"]).to eq(120)
        expect(body["days"].size).to eq(2)
      end
    end

    it "月の形式が不正なら 422" do
      get "/monthly_reports/2026-13", headers: auth_headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]["code"]).to eq("invalid_month")
    end

    it "未認証は 401" do
      get "/monthly_reports/2026-06"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
