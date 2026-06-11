# ドメインの状態遷移が不正なときに投げる共通エラー。
# Controller 側で code 付きの 422 にマップする（ApplicationController）。
class InvalidTransition < StandardError
  attr_reader :code

  def initialize(code, message)
    @code = code
    super(message)
  end
end
