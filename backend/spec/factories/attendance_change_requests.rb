FactoryBot.define do
  factory :attendance_change_request do
    association :user
    # 対象勤怠は申請者本人のもの（バリデーション）
    attendance { association :attendance, user: user }
    proposed_clock_in_at { Time.zone.local(2026, 6, 12, 9, 0) }
    proposed_clock_out_at { nil }
    reason { "打刻し忘れたため" }
    status { :pending }
  end
end
