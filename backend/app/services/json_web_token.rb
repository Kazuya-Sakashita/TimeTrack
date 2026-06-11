# JWT の発行・検証を担うサービス。
# 秘密鍵は ENV（JWT_SECRET_KEY）。未設定時は Rails の secret_key_base にフォールバック。
class JsonWebToken
  ALGORITHM = "HS256".freeze
  DEFAULT_EXP = 24.hours

  class << self
    def encode(payload, exp: DEFAULT_EXP.from_now)
      JWT.encode(payload.merge(exp: exp.to_i), secret, ALGORITHM)
    end

    # 検証に失敗（改ざん・期限切れ・不正形式）した場合は nil を返す
    def decode(token)
      body, = JWT.decode(token, secret, true, algorithm: ALGORITHM)
      body.with_indifferent_access
    rescue JWT::DecodeError, JWT::ExpiredSignature
      nil
    end

    private

    def secret
      ENV.fetch("JWT_SECRET_KEY") { Rails.application.secret_key_base }
    end
  end
end
