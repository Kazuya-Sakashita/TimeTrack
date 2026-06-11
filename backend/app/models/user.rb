class User < ApplicationRecord
  include HasPublicId
  has_public_id_prefix "usr"

  has_secure_password

  has_many :attendances, dependent: :destroy
  has_many :attendance_change_requests, dependent: :destroy

  # role はバックエンド内部では integer、API では文字列で扱う
  enum :role, { employee: 0, manager: 1, admin: 2 }

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  normalizes :email, with: ->(email) { email.strip.downcase }
end
