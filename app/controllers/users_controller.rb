class UsersController < ApplicationController
  def index
    @users = User.includes(:referrals).all
  end

  def new
    @user = User.new
  end

  def create
    if invalid_referral_code?
      render_error('Invalid Referral Code')
      return
    end

    if user = UserSignUpService.new(user_params).call
      flash[:notice] = 'User Created Successfully!'
      redirect_to new_user_path
    else
      render_error('Invalid Name or Email')
    end
  end

  private

  # TODO: Move this method to ApplicationController and make it more generic
  # to handle error rendering for all controllers.
  def render_error(message)
    @user = User.new(user_params)
    flash.now[:error] = message
    render :new, status: :unprocessable_entity
  end

  def user_params
    params.require(:user).permit(:name, :email, :referral_code)
  end

  def invalid_referral_code?
    referral_code = user_params[:referral_code]
    return false if referral_code.blank?
    
    !User.exists?(referral_code: referral_code)
  end
end 