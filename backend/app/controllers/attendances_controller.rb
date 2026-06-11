class AttendancesController < ApplicationController
  before_action :authenticate_request

  # GET /attendances
  def index
    scope = policy_scope(Attendance).order(work_date: :desc)

    page = [params.fetch(:page, 1).to_i, 1].max
    per_page = params.fetch(:perPage, 20).to_i.clamp(1, 100)
    total = scope.count
    records = scope.offset((page - 1) * per_page).limit(per_page)

    render json: {
      attendances: records.map { |a| AttendanceSerializer.call(a) },
      pagination: {
        page:,
        perPage: per_page,
        total:,
        totalPages: (total.to_f / per_page).ceil,
      },
    }
  end

  # POST /attendances/clock-in
  def clock_in
    if current_user.attendances.exists?(work_date: Date.current)
      return render json: { error: { code: "already_clocked_in",
                                     message: "本日は既に出勤打刻済みです" } },
                    status: :unprocessable_entity
    end

    attendance = current_user.attendances.build(
      work_date: Date.current,
      clock_in_at: Time.current,
      status: :working,
    )
    authorize attendance, :create? # Pundit: 自分の打刻のみ

    attendance.save!
    render json: AttendanceSerializer.call(attendance), status: :created
  end

  # POST /attendances/clock-out
  def clock_out
    attendance = current_user.attendances.find_by(work_date: Date.current)

    if attendance.nil?
      return render json: { error: { code: "not_clocked_in",
                                     message: "本日の出勤打刻がありません" } },
                    status: :unprocessable_entity
    end

    if attendance.finished?
      return render json: { error: { code: "already_clocked_out",
                                     message: "本日は既に退勤打刻済みです" } },
                    status: :unprocessable_entity
    end

    authorize attendance, :update? # Pundit: 自分の打刻のみ

    attendance.update!(clock_out_at: Time.current, status: :finished)
    render json: AttendanceSerializer.call(attendance), status: :ok
  end

  # POST /attendances/break-start
  def break_start
    attendance = current_user.attendances.find_by(work_date: Date.current)

    return render_error("not_clocked_in", "本日の出勤打刻がありません") if attendance.nil?
    return render_error("already_clocked_out", "本日は既に退勤打刻済みです") if attendance.finished?
    return render_error("already_on_break", "既に休憩中です") if attendance.on_break?

    authorize attendance, :update?

    attendance.attendance_breaks.create!(started_at: Time.current)
    attendance.update!(status: :on_break)
    render json: AttendanceSerializer.call(attendance), status: :ok
  end

  # POST /attendances/break-end
  def break_end
    attendance = current_user.attendances.find_by(work_date: Date.current)

    return render_error("not_clocked_in", "本日の出勤打刻がありません") if attendance.nil?

    open_break = attendance.attendance_breaks.open.first
    return render_error("not_on_break", "休憩中ではありません") if open_break.nil?

    authorize attendance, :update?

    open_break.update!(ended_at: Time.current)
    attendance.update!(status: :working)
    render json: AttendanceSerializer.call(attendance), status: :ok
  end

  private

  def render_error(code, message)
    render json: { error: { code:, message: } }, status: :unprocessable_entity
  end
end
