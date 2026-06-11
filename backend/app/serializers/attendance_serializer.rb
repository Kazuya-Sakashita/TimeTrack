# Attendance を外部公開用に整形する。id は public_id（内部 id 非公開）。
class AttendanceSerializer
  def self.call(attendance)
    {
      id: attendance.public_id,
      workDate: attendance.work_date.iso8601,
      clockInAt: attendance.clock_in_at&.iso8601,
      clockOutAt: attendance.clock_out_at&.iso8601,
      workMinutes: attendance.worked_minutes,
      breakMinutes: attendance.break_minutes,
      status: attendance.status,
    }
  end
end
