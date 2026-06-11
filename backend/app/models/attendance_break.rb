class AttendanceBreak < ApplicationRecord
  include HasPublicId
  has_public_id_prefix "brk"

  belongs_to :attendance

  validates :started_at, presence: true

  # 終了していない（休憩中の）レコード
  scope :open, -> { where(ended_at: nil) }

  # 休憩時間（分）。終了前は nil。
  def minutes
    return nil unless started_at && ended_at

    ((ended_at - started_at) / 60).floor
  end
end
