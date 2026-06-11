class AttendancePolicy < ApplicationPolicy
  # 自分の打刻のみ作成できる
  def create?
    user.present? && record.user_id == user.id
  end
end
