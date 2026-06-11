class AttendanceChangeRequest < ApplicationRecord
  include HasPublicId
  has_public_id_prefix "acr"

  belongs_to :user                              # 申請者
  belongs_to :attendance                        # 対象勤怠
  belongs_to :reviewer, class_name: "User", optional: true

  # status: 申請中 / 承認 / 却下
  enum :status, { pending: 0, approved: 1, rejected: 2 }

  validates :reason, presence: true
  validate :at_least_one_proposed_time
  validate :attendance_owned_by_applicant

  # 承認: 対象勤怠に修正時刻を反映し、承認済みにする
  def approve!(reviewer:, comment: nil)
    ensure_pending!

    transaction do
      apply_to_attendance!
      update!(status: :approved, reviewer:, reviewed_at: Time.current, review_comment: comment)
    end
  end

  # 却下: 勤怠は変更せず却下済みにする
  def reject!(reviewer:, comment: nil)
    ensure_pending!

    update!(status: :rejected, reviewer:, reviewed_at: Time.current, review_comment: comment)
  end

  private

  def ensure_pending!
    raise InvalidTransition.new("not_pending", "申請中の申請のみ承認/却下できます") unless pending?
  end

  def apply_to_attendance!
    attrs = {}
    attrs[:clock_in_at] = proposed_clock_in_at if proposed_clock_in_at.present?
    attrs[:clock_out_at] = proposed_clock_out_at if proposed_clock_out_at.present?
    attendance.update!(attrs) if attrs.any?
  end

  def at_least_one_proposed_time
    return if proposed_clock_in_at.present? || proposed_clock_out_at.present?

    errors.add(:base, "修正後の時刻を1つ以上指定してください")
  end

  def attendance_owned_by_applicant
    return if attendance.nil? || user_id.nil?

    errors.add(:attendance, "は自分の勤怠ではありません") if attendance.user_id != user_id
  end
end
