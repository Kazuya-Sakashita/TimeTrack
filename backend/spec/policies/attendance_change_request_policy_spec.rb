require "rails_helper"

RSpec.describe AttendanceChangeRequestPolicy do
  let(:applicant) { create(:user) }
  let(:other) { create(:user) }
  let(:manager) { create(:user, :manager) }
  let(:request) { create(:attendance_change_request, user: applicant) }

  describe "権限" do
    it "申請者は作成・閲覧できる" do
      policy = described_class.new(applicant, request)
      expect(policy.create?).to be(true)
      expect(policy.show?).to be(true)
    end

    it "無関係な従業員は閲覧できない" do
      expect(described_class.new(other, request).show?).to be(false)
    end

    it "manager は閲覧できる" do
      expect(described_class.new(manager, request).show?).to be(true)
    end

    it "manager は他人の申請を承認できる" do
      expect(described_class.new(manager, request).update?).to be(true)
    end

    it "申請者本人は承認できない" do
      expect(described_class.new(applicant, request).update?).to be(false)
    end

    it "manager でも自分の申請は承認できない" do
      own = create(:attendance_change_request, user: manager)
      expect(described_class.new(manager, own).update?).to be(false)
    end
  end

  describe "Scope" do
    it "従業員は自分の申請のみ" do
      mine = create(:attendance_change_request, user: applicant)
      create(:attendance_change_request, user: other)

      resolved = AttendanceChangeRequestPolicy::Scope
                 .new(applicant, AttendanceChangeRequest.all).resolve

      expect(resolved).to contain_exactly(mine)
    end

    it "manager は全件" do
      create(:attendance_change_request, user: applicant)
      create(:attendance_change_request, user: other)

      resolved = AttendanceChangeRequestPolicy::Scope
                 .new(manager, AttendanceChangeRequest.all).resolve

      expect(resolved.count).to eq(2)
    end
  end
end
