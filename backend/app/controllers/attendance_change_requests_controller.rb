class AttendanceChangeRequestsController < ApplicationController
  before_action :authenticate_request

  # GET /attendance_change_requests
  def index
    requests = policy_scope(AttendanceChangeRequest)
               .includes(:user, :attendance)
               .order(created_at: :desc)
    render json: requests.map { |r| AttendanceChangeRequestSerializer.call(r) }
  end

  # GET /attendance_change_requests/:id
  def show
    request = AttendanceChangeRequest.find_by!(public_id: params[:id])
    authorize request
    render json: AttendanceChangeRequestSerializer.call(request)
  end

  # PATCH /attendance_change_requests/:id （承認・却下＝状態更新）
  def update
    change_request = AttendanceChangeRequest.find_by!(public_id: params[:id])
    authorize change_request

    case params[:status]
    when "approved"
      change_request.approve!(reviewer: current_user, comment: params[:comment])
    when "rejected"
      change_request.reject!(reviewer: current_user, comment: params[:comment])
    else
      return render_error("unsupported_update", "status は approved / rejected のいずれかです")
    end

    render json: AttendanceChangeRequestSerializer.call(change_request)
  end

  # POST /attendance_change_requests
  def create
    attendance = current_user.attendances.find_by!(public_id: params[:attendanceId])

    change_request = current_user.attendance_change_requests.build(
      attendance:,
      proposed_clock_in_at: params[:proposedClockInAt],
      proposed_clock_out_at: params[:proposedClockOutAt],
      reason: params[:reason],
      status: :pending,
    )
    authorize change_request

    change_request.save!
    render json: AttendanceChangeRequestSerializer.call(change_request), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render_error("validation_error", e.record.errors.full_messages.join(", "))
  end
end
