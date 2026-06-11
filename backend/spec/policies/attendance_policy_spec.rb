require "rails_helper"

RSpec.describe AttendancePolicy do
  let(:owner) { create(:user) }
  let(:other) { create(:user) }

  describe "権限" do
    it "自分の勤怠は作成・更新できる" do
      record = build(:attendance, user: owner)
      policy = described_class.new(owner, record)

      expect(policy.create?).to be(true)
      expect(policy.update?).to be(true)
    end

    it "他人の勤怠は作成・更新できない" do
      record = build(:attendance, user: other)
      policy = described_class.new(owner, record)

      expect(policy.create?).to be(false)
      expect(policy.update?).to be(false)
    end
  end

  describe "Scope" do
    it "自分の勤怠のみに絞り込む" do
      mine = create(:attendance, user: owner, work_date: Date.new(2026, 6, 10))
      create(:attendance, user: other, work_date: Date.new(2026, 6, 10))

      resolved = AttendancePolicy::Scope.new(owner, Attendance.all).resolve

      expect(resolved).to contain_exactly(mine)
    end
  end
end
