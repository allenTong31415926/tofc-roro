class UsersController < ApplicationController
  def create
    if invalid_referral_code?
      render json: { errors: 'Invalid Referral Code' }, status: :unprocessable_entity
      return
    end

    if user = UserSignUpService.new(user_params).call
      render json: user, status: :created
    else
      render json: { errors: 'Invalid Name or Email' }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :referral_code)
  end

  def invalid_referral_code?
    referral_code = user_params[:referral_code]
    return false if referral_code.blank?  # Skip validation if no referral code provided
    
    !User.exists?(referral_code: referral_code)
  end
end 