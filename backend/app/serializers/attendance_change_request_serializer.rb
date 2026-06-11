# 修正申請を外部公開用に整形する。id は public_id（内部 id 非公開）。
class AttendanceChangeRequestSerializer
  def self.call(request)
    {
      id: request.public_id,
      attendanceId: request.attendance.public_id,
      applicantName: request.user.name,
      proposedClockInAt: request.proposed_clock_in_at&.iso8601,
      proposedClockOutAt: request.proposed_clock_out_at&.iso8601,
      reason: request.reason,
      status: request.status,
      reviewComment: request.review_comment,
      reviewedAt: request.reviewed_at&.iso8601,
      createdAt: request.created_at.iso8601
    }
  end
end
