class AttendancePolicy < ApplicationPolicy
  # 自分の打刻のみ作成できる
  def create?
    own?
  end

  # 自分の打刻のみ更新できる（退勤・休憩など）
  def update?
    own?
  end

  private

  def own?
    user.present? && record.user_id == user.id
  end
end
