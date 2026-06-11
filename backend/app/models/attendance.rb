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

  # 退勤（状態変更）
  def clock_out!
    raise InvalidTransition.new("already_clocked_out", "本日は既に退勤打刻済みです") if finished?
    raise InvalidTransition.new("on_break", "休憩を終了してから退勤してください") if on_break?

    update!(clock_out_at: Time.current, status: :finished)
  end

  # 休憩開始（breaks サブリソースの作成）
  def start_break!
    raise InvalidTransition.new("already_clocked_out", "本日は既に退勤打刻済みです") if finished?
    raise InvalidTransition.new("already_on_break", "既に休憩中です") if on_break?

    attendance_breaks.create!(started_at: Time.current).tap do
      update!(status: :on_break)
    end
  end

  # 休憩終了（breaks サブリソースの更新）
  def finish_break!(attendance_break)
    raise InvalidTransition.new("not_on_break", "休憩中ではありません") if attendance_break.ended_at.present?

    attendance_break.update!(ended_at: Time.current)
    update!(status: :working)
    attendance_break
  end

  # 進行中（未終了）の休憩
  def open_break
    attendance_breaks.open.first
  end

  # 休憩時間の合計（分）。終了済みの休憩のみ集計する。
  def break_minutes
    attendance_breaks.filter_map(&:minutes).sum
  end

  # 勤務時間（分、休憩控除後）。退勤前は nil。
  def worked_minutes
    return nil unless clock_in_at && clock_out_at

    gross = ((clock_out_at - clock_in_at) / 60).floor
    [ gross - break_minutes, 0 ].max
  end
end
