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
        # 別ユーザーの勤怠（一覧に含まれてはいけない）
        create(:attendance, user: create(:user), work_date: Date.new(2026, 6, 11))
      end

      it "自分の勤怠のみを新しい日付順で返す" do
        get "/attendances", headers: auth_headers

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["attendances"].size).to eq(2)
        dates = body["attendances"].map { |a| a["workDate"] }
        expect(dates).to eq(["2026-06-11", "2026-06-10"])
      end

      it "ページングする" do
        get "/attendances", params: { page: 1, perPage: 1 }, headers: auth_headers

        body = JSON.parse(response.body)
        expect(body["attendances"].size).to eq(1)
        expect(body["pagination"]).to include(
          "page" => 1, "perPage" => 1, "total" => 2, "totalPages" => 2,
        )
      end
    end

    context "未認証" do
      it "401 を返す" do
        get "/attendances"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

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

  describe "POST /attendances/clock-out" do
    context "出勤中" do
      before do
        create(:attendance, user: user, work_date: Date.current,
                            clock_in_at: 8.hours.ago, status: :working)
      end

      it "200 で退勤済み・勤務時間を返す" do
        post "/attendances/clock-out", headers: auth_headers

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["status"]).to eq("finished")
        expect(body["clockOutAt"]).to be_present
        expect(body["workMinutes"]).to be_within(2).of(480)
      end
    end

    context "本日未出勤" do
      it "422 を返す" do
        post "/attendances/clock-out", headers: auth_headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]["code"]).to eq("not_clocked_in")
      end
    end

    context "既に退勤済み" do
      before do
        create(:attendance, user: user, work_date: Date.current,
                            clock_in_at: 8.hours.ago, clock_out_at: 1.hour.ago,
                            status: :finished)
      end

      it "422 を返す" do
        post "/attendances/clock-out", headers: auth_headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]["code"]).to eq("already_clocked_out")
      end
    end

    context "未認証" do
      it "401 を返す" do
        post "/attendances/clock-out"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /attendances/break-start" do
    context "勤務中" do
      before { create(:attendance, user: user, work_date: Date.current, status: :working) }

      it "200 で休憩中になる" do
        post "/attendances/break-start", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["status"]).to eq("on_break")
        expect(user.attendances.first.attendance_breaks.open.count).to eq(1)
      end
    end

    context "本日未出勤" do
      it "422 not_clocked_in" do
        post "/attendances/break-start", headers: auth_headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]["code"]).to eq("not_clocked_in")
      end
    end

    context "既に休憩中" do
      before { create(:attendance, user: user, work_date: Date.current, status: :on_break) }

      it "422 already_on_break" do
        post "/attendances/break-start", headers: auth_headers
        expect(JSON.parse(response.body)["error"]["code"]).to eq("already_on_break")
      end
    end

    context "未認証" do
      it "401" do
        post "/attendances/break-start"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /attendances/break-end" do
    context "休憩中" do
      let!(:attendance) do
        create(:attendance, user: user, work_date: Date.current, status: :on_break)
      end
      before { create(:attendance_break, attendance: attendance, started_at: 10.minutes.ago) }

      it "200 で勤務中に戻り休憩が終了する" do
        post "/attendances/break-end", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["status"]).to eq("working")
        expect(attendance.attendance_breaks.open.count).to eq(0)
      end
    end

    context "休憩中でない" do
      before { create(:attendance, user: user, work_date: Date.current, status: :working) }

      it "422 not_on_break" do
        post "/attendances/break-end", headers: auth_headers
        expect(JSON.parse(response.body)["error"]["code"]).to eq("not_on_break")
      end
    end

    context "未認証" do
      it "401" do
        post "/attendances/break-end"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
