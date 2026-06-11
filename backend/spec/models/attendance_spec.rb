require "rails_helper"

RSpec.describe Attendance, type: :model do
  describe "#worked_minutes" do
    it "退勤前は nil" do
      attendance = build(:attendance, clock_in_at: Time.current, clock_out_at: nil)
      expect(attendance.worked_minutes).to be_nil
    end

    it "休憩を控除した勤務時間（分）を返す" do
      attendance = create(:attendance,
                          clock_in_at: Time.zone.local(2026, 6, 12, 9, 0),
                          clock_out_at: Time.zone.local(2026, 6, 12, 18, 0),
                          status: :finished)
      # 60分の休憩
      create(:attendance_break, attendance: attendance,
                                started_at: Time.zone.local(2026, 6, 12, 12, 0),
                                ended_at: Time.zone.local(2026, 6, 12, 13, 0))

      # 9h(540分) - 休憩60分 = 480分
      expect(attendance.break_minutes).to eq(60)
      expect(attendance.worked_minutes).to eq(480)
    end
  end
end
