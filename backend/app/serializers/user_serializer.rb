# User を外部公開用の形に整形する。
# 内部連番 id は出さず、public_id を "id" として返す（database-policy.md）。
class UserSerializer
  def self.call(user)
    {
      id: user.public_id,
      email: user.email,
      name: user.name,
      role: user.role,
    }
  end
end
