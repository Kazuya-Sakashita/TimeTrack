FactoryBot.define do
  factory :attendance_break do
    association :attendance
    started_at { 1.hour.ago }
    ended_at { nil }

    trait :finished do
      started_at { 2.hours.ago }
      ended_at { 1.hour.ago }
    end
  end
end
