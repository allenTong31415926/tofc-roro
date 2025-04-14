# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  describe 'GET #index' do
    let!(:user1) { create(:user, name: 'John Doe', email: 'john@example.com') }
    let!(:user2) { create(:user, name: 'Jane Smith', email: 'jane@example.com') }
    let!(:referral) { create(:user, name: 'Bob Wilson', email: 'bob@example.com', referred_by: user1) }

    before { get :index }

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'renders the index template' do
      expect(response).to render_template(:index)
    end

    it 'assigns all users to @users' do
      expect(assigns(:users)).to match_array([user1, user2, referral])
    end

    it 'eager loads referrals' do
      expect(assigns(:users).first.association(:referrals).loaded?).to be true
    end
  end

  describe 'GET #new' do
    before { get :new }

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'renders the new template' do
      expect(response).to render_template(:new)
    end

    it 'assigns a new user to @user' do
      expect(assigns(:user)).to be_a_new(User)
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        user: {
          name: 'John Doe',
          email: 'john@example.com'
        }
      }
    end

    context 'with valid params' do
      it 'creates a new user' do
        expect {
          post :create, params: valid_params
        }.to change(User, :count).by(1)
      end

      it 'redirects to new user path with success notice' do
        post :create, params: valid_params
        expect(response).to redirect_to(new_user_path)
        expect(flash[:notice]).to eq('User Created Successfully!')
      end

      it 'sets the correct user attributes' do
        post :create, params: valid_params
        user = User.last
        expect(user.name).to eq('John Doe')
        expect(user.email).to eq('john@example.com')
      end
    end

    context 'with invalid params' do
      let(:invalid_params) do
        {
          user: {
            name: '',
            email: 'invalid'
          }
        }
      end

      it 'does not create a new user' do
        expect {
          post :create, params: invalid_params
        }.not_to change(User, :count)
      end

      it 'renders new template with unprocessable_entity status' do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'sets error flash message' do
        post :create, params: invalid_params
        expect(flash.now[:error]).to eq('Invalid Name or Email')
      end
    end

    context 'with referral code' do
      let!(:referrer) { create(:user) }
      let(:params_with_referral) do
        {
          user: valid_params[:user].merge(referral_code: referrer.referral_code)
        }
      end

      it 'creates a user with referral' do
        expect {
          post :create, params: params_with_referral
        }.to change(User, :count).by(1)
      end

      it 'links the referrer correctly' do
        post :create, params: params_with_referral
        expect(User.last.referred_by).to eq(referrer)
      end

      context 'with invalid referral code' do
        let(:params_with_invalid_referral) do
          {
            user: valid_params[:user].merge(referral_code: 'INVALID')
          }
        end

        it 'does not create a user' do
          expect {
            post :create, params: params_with_invalid_referral
          }.not_to change(User, :count)
        end

        it 'renders new template with error' do
          post :create, params: params_with_invalid_referral
          expect(response).to render_template(:new)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(flash.now[:error]).to eq('Invalid Referral Code')
        end
      end
    end

    context 'when service fails' do
      before do
        allow(UserSignUpService).to receive(:new).and_return(
          instance_double(UserSignUpService, call: false)
        )
      end

      it 'renders new template with error' do
        post :create, params: valid_params
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:error]).to eq('Invalid Name or Email')
      end
    end
  end
end 