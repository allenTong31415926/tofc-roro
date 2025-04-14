# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsersController, type: :controller do
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

      it 'returns http success' do
        post :create, params: valid_params
        expect(response).to have_http_status(:success)
      end

      it 'returns the created user as json' do
        post :create, params: valid_params
        expect(response.content_type).to eq('application/json; charset=utf-8')
        
        json_response = JSON.parse(response.body)
        expect(json_response).to include(
          'name' => 'John Doe',
          'email' => 'john@example.com'
        )
      end

      it 'generates a referral code for the user' do
        post :create, params: valid_params
        json_response = JSON.parse(response.body)
        expect(json_response['referral_code']).to match(/^[A-Z0-9]{8}$/)
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

      it 'returns http unprocessable entity' do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns validation errors as json' do
        post :create, params: invalid_params
        expect(response.content_type).to eq('application/json; charset=utf-8')
        
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to eq('Invalid Name or Email')
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

        json_response = JSON.parse(response.body)
        expect(json_response['referred_by_id']).to eq(referrer.id)
      end

      it 'increments referrer reward count' do
        expect {
          post :create, params: params_with_referral
          referrer.reload
        }.to change(referrer, :reward_count).by(1)
      end

      context 'with invalid referral code' do
        let(:params_with_invalid_referral) do
          {
            user: valid_params[:user].merge(referral_code: 'INVALID')
          }
        end

        it 'returns http unprocessable entity' do
          post :create, params: params_with_invalid_referral
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error message' do
          post :create, params: params_with_invalid_referral
          json_response = JSON.parse(response.body)
          expect(json_response['errors']).to eq('Invalid Referral Code')
        end

        it 'does not create a user' do
          expect {
            post :create, params: params_with_invalid_referral
          }.not_to change(User, :count)
        end
      end
    end

    context 'when service fails' do
      let(:failed_user) { build(:user) }
      
      before do
        allow(UserSignUpService).to receive(:new).and_return(
          instance_double(UserSignUpService, call: false)
        )
      end

      it 'returns http unprocessable entity' do
        post :create, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error message' do
        post :create, params: valid_params
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to eq('Invalid Name or Email')
      end
    end
  end
end 