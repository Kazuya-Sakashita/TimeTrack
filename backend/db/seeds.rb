# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# 開発用シードデータ。`bin/rails db:seed` で投入。
# パスワードはすべて "password"（開発専用）。
[
  { email: "admin@example.com", name: "管理 太郎", role: :admin },
  { email: "manager@example.com", name: "主任 花子", role: :manager },
  { email: "employee@example.com", name: "社員 次郎", role: :employee }
].each do |attrs|
  user = User.find_or_initialize_by(email: attrs[:email])
  user.assign_attributes(name: attrs[:name], role: attrs[:role], password: "password")
  user.save!
  puts "seed user: #{user.email} (#{user.role}) #{user.public_id}"
end
