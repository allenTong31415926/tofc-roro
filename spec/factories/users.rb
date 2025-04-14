FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:referral_code) { |n| "CODE#{n.to_s.rjust(4, '0')}" }
    reward_count { 0 }
    reward_status { :bronze }

    trait :bronze do
      reward_count { 1 }
      reward_status { :bronze }
    end

    trait :silver do
      reward_count { 5 }
      reward_status { :silver }
    end

    trait :gold do
      reward_count { 10 }
      reward_status { :gold }
    end
  end
end 