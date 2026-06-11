class AttendancesController < ApplicationController
  before_action :authenticate_request

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
end
