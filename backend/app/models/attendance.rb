class Attendance < ApplicationRecord
  include HasPublicId
  has_public_id_prefix "att"

  belongs_to :user

  # status: 出勤中 / 退勤済
  enum :status, { working: 0, finished: 1 }

  validates :work_date, presence: true,
                        uniqueness: { scope: :user_id, message: "は既に打刻済みです" }
  validates :clock_in_at, presence: true

  # 勤務時間（分）。退勤前は nil。休憩控除は Slice 5 で対応予定。
  def worked_minutes
    return nil unless clock_in_at && clock_out_at

    ((clock_out_at - clock_in_at) / 60).floor
  end
end
