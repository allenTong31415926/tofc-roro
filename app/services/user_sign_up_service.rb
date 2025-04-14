class UserSignUpService
  def initialize(params)
    @params = params
    @referral_code = params.delete(:referral_code)
  end

  def call
    ActiveRecord::Base.transaction do
      create_user
      handle_referral if @referral_code.present?
      @user
    end
  rescue ActiveRecord::RecordInvalid => e
    @user = e.record
    false
  end

  private

  attr_reader :params

  def create_user
    @user = User.create!(params)
  end

  def handle_referral
    referrer = User.find_by!(referral_code: @referral_code)
    @user.update!(referred_by: referrer)
    update_referrer_rewards(referrer)
  end

  def update_referrer_rewards(referrer)
    referrer.increment!(:reward_count)
    update_referrer_status(referrer)
  end

  def update_referrer_status(referrer)
    User::REWARD_THRESHOLDS.each do |status, range|
      if (range[:min]..range[:max]).cover?(referrer.reward_count)
        referrer.update_column(:reward_status, User.reward_statuses[status])
        break
      end
    end
  end
end 