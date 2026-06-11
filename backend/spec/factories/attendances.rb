FactoryBot.define do
  factory :attendance do
    association :user
    work_date { Date.current }
    clock_in_at { Time.current }
    status { :working }
  end
end
