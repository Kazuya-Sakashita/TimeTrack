# 休憩（attendance のサブリソース）。
# 休憩開始＝create、休憩終了＝update。レスポンスは親 Attendance の最新状態を返す
# （ダッシュボードが勤怠中心のため。backend-controller-design.md）。
class BreaksController < ApplicationController
  before_action :authenticate_request

  # POST /attendances/:attendance_id/breaks
  def create
    attendance = find_attendance
    authorize attendance, :update?

    attendance.start_break!
    render json: AttendanceSerializer.call(attendance), status: :created
  end

  # PATCH /attendances/:attendance_id/breaks/:id
  def update
    attendance = find_attendance
    authorize attendance, :update?

    attendance_break = attendance.attendance_breaks.find_by!(public_id: params[:id])
    attendance.finish_break!(attendance_break)
    render json: AttendanceSerializer.call(attendance)
  end

  private

  def find_attendance
    current_user.attendances.find_by!(public_id: params[:attendance_id])
  end
end
