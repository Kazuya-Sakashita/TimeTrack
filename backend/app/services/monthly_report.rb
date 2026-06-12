# 月次の勤怠集計（読み取り専用・保存しない）。Attendance から都度算出する。
# 残業 = 1日の勤務分が所定労働（STANDARD_WORK_MINUTES）を超えた分の合計。
class MonthlyReport
  STANDARD_WORK_MINUTES = 480 # 所定労働 8h（当面固定。設定化は別途）

  attr_reader :year, :month

  # "YYYY-MM" をパースして year/month を返す。不正なら nil。
  def self.parse_month(str)
    return nil unless str.to_s.match?(/\A\d{4}-\d{2}\z/)

    year, month = str.split("-").map(&:to_i)
    return nil unless month.between?(1, 12)

    [ year, month ]
  end

  def initialize(user:, year:, month:)
    @user = user
    @year = year
    @month = month
  end

  def attendances
    @attendances ||= @user.attendances
                          .where(work_date: range)
                          .includes(:attendance_breaks)
                          .order(:work_date)
  end

  def days
    attendances.map do |attendance|
      worked = attendance.worked_minutes
      {
        date: attendance.work_date.iso8601,
        workMinutes: worked,
        breakMinutes: attendance.break_minutes,
        overtimeMinutes: overtime_for(worked),
        status: attendance.status
      }
    end
  end

  def working_days
    attendances.size
  end

  def total_work_minutes
    attendances.sum { |a| a.worked_minutes || 0 }
  end

  def total_break_minutes
    attendances.sum(&:break_minutes)
  end

  def overtime_minutes
    attendances.sum { |a| overtime_for(a.worked_minutes) }
  end

  private

  def range
    Date.new(@year, @month, 1)..Date.new(@year, @month, -1)
  end

  def overtime_for(worked)
    return 0 if worked.nil?

    [ worked - STANDARD_WORK_MINUTES, 0 ].max
  end
end
