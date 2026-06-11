class Attendance < ApplicationRecord
  include HasPublicId
  has_public_id_prefix "att"

  belongs_to :user
  has_many :attendance_breaks, dependent: :destroy

  # status: 出勤中 / 退勤済 / 休憩中
  # 既存データ互換のため working=0, finished=1 を維持し on_break=2 を追加
  enum :status, { working: 0, finished: 1, on_break: 2 }

  validates :work_date, presence: true,
                        uniqueness: { scope: :user_id, message: "は既に打刻済みです" }
  validates :clock_in_at, presence: true

  # 休憩時間の合計（分）。終了済みの休憩のみ集計する。
  def break_minutes
    attendance_breaks.filter_map(&:minutes).sum
  end

  # 勤務時間（分、休憩控除後）。退勤前は nil。
  def worked_minutes
    return nil unless clock_in_at && clock_out_at

    gross = ((clock_out_at - clock_in_at) / 60).floor
    [gross - break_minutes, 0].max
  end
end
