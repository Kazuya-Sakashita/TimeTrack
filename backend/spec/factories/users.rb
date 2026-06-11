FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { "テスト 太郎" }
    password { "password123" }
    role { :employee }

    trait :admin do
      role { :admin }
    end

    trait :manager do
      role { :manager }
    end
  end
end
