# Pundit の基底ポリシー。各リソースの Policy はこれを継承する。
# user = current_user（pundit_user）、record = 対象オブジェクト。
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?    = false
  def show?     = false
  def create?   = false
  def new?      = create?
  def update?   = false
  def edit?     = update?
  def destroy?  = false

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "#{self.class}#resolve を実装してください"
    end

    private

    attr_reader :user, :scope
  end
end
