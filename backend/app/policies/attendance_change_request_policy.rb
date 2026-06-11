class AttendanceChangeRequestPolicy < ApplicationPolicy
  # 従業員は自分の申請、manager/admin は全件
  class Scope < ApplicationPolicy::Scope
    def resolve
      reviewer? ? scope.all : scope.where(user_id: user.id)
    end

    private

    def reviewer?
      user.manager? || user.admin?
    end
  end

  # 自分の勤怠に対してのみ申請できる
  def create?
    own?
  end

  # 自分の申請、または承認者（manager/admin）は閲覧できる
  def show?
    own? || reviewer?
  end

  # 承認/却下は承認者のみ。申請者自身は承認できない。
  def update?
    reviewer? && !own?
  end

  private

  def own?
    user.present? && record.user_id == user.id
  end

  def reviewer?
    user.present? && (user.manager? || user.admin?)
  end
end
