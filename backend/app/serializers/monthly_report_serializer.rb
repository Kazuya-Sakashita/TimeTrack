# 月次集計を外部公開用に整形する。
class MonthlyReportSerializer
  def self.call(report, month_param:)
    {
      month: month_param,
      workingDays: report.working_days,
      totalWorkMinutes: report.total_work_minutes,
      totalBreakMinutes: report.total_break_minutes,
      overtimeMinutes: report.overtime_minutes,
      days: report.days
    }
  end
end
