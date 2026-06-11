class Attendance < ApplicationRecord
  include HasPublicId
  has_public_id_prefix "att"

  belongs_to :user

  # status: 出勤中 / 退勤済
  enum :status, { working: 0, finished: 1 }

  validates :work_date, presence: true,
                        uniqueness: { scope: :user_id, message: "は既に打刻済みです" }
  validates :clock_in_at, presence: true
end
