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

  # GET /attendances/:id
  def show
    attendance = find_attendance
    authorize attendance
    render json: AttendanceSerializer.call(attendance)
  end

  # POST /attendances （出勤＝勤怠の作成）
  def create
    if current_user.attendances.exists?(work_date: Date.current)
      return render_error("already_clocked_in", "本日は既に出勤打刻済みです")
    end

    attendance = current_user.attendances.build(
      work_date: Date.current,
      clock_in_at: Time.current,
      status: :working,
    )
    authorize attendance

    attendance.save!
    render json: AttendanceSerializer.call(attendance), status: :created
  end

  # PATCH /attendances/:id （状態変更。退勤＝status: finished）
  def update
    attendance = find_attendance
    authorize attendance

    case params[:status]
    when "finished"
      attendance.clock_out!
      render json: AttendanceSerializer.call(attendance)
    else
      render_error("unsupported_update", "サポートされていない更新です")
    end
  end

  private

  def find_attendance
    current_user.attendances.find_by!(public_id: params[:id])
  end
end
