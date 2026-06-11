# 外部公開用 ID の生成ロジック（純粋関数。DB 非依存でテストしやすい）。
# 内部連番 id は公開せず、prefix 付きの public_id を外部に出す（database-policy.md）。
#   例: PublicId.generate(prefix: "usr") => "usr_a1B2c3D4e5F6"
module PublicId
  # 衝突しにくいランダム部の長さ
  RANDOM_LENGTH = 12

  module_function

  def generate(prefix:, length: RANDOM_LENGTH)
    raise ArgumentError, "prefix is required" if prefix.blank?

    "#{prefix}_#{SecureRandom.alphanumeric(length)}"
  end
end
