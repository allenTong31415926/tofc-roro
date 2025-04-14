# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserSignUpService do
  describe '#call' do
    let(:valid_params) do
      {
        name: 'John Doe',
        email: 'john@example.com'
      }
    end

    context 'when params are valid' do
      it 'creates a new user' do
        expect {
          described_class.new(valid_params).call
        }.to change(User, :count).by(1)
      end

      it 'sets user attributes correctly' do
        user = described_class.new(valid_params).call
        expect(user).to have_attributes(
          name: 'John Doe',
          email: 'john@example.com',
          reward_count: 0,
          reward_status: 'bronze'
        )
      end

      it 'generates a referral code' do
        user = described_class.new(valid_params).call
        expect(user.referral_code).to match(/^[A-Z0-9]{8}$/)
      end
    end

    context 'when params are invalid' do
      let(:invalid_params) { { name: '', email: 'invalid' } }

      it 'does not create a user' do
        expect {
          described_class.new(invalid_params).call
        }.not_to change(User, :count)
      end

      it 'returns false' do
        result = described_class.new(invalid_params).call
        expect(result).to be_falsey
      end
    end

    context 'with referral code' do
      let!(:referrer) { create(:user) }
      let(:params_with_referral) { valid_params.merge(referral_code: referrer.referral_code) }

      it 'links the referrer' do
        user = described_class.new(params_with_referral).call
        expect(user).to be_persisted
        expect(user.referred_by).to eq(referrer)
      end

      it 'increments referrer reward count' do
        expect {
          described_class.new(params_with_referral).call
          referrer.reload
        }.to change(referrer, :reward_count).by(1)
      end

      context 'when referral would make referrer reach silver status' do
        let!(:referrer) { create(:user, reward_count: 4) }

        it 'updates referrer status to silver' do
          expect {
            described_class.new(params_with_referral).call
            referrer.reload
          }.to change(referrer, :reward_status).from('bronze').to('silver')
        end
      end

      context 'when referral would make referrer reach gold status' do
        let!(:referrer) { create(:user, reward_count: 9, reward_status: :silver) }

        it 'updates referrer status to gold' do
          expect {
            described_class.new(params_with_referral).call
            referrer.reload
          }.to change(referrer, :reward_status).from('silver').to('gold')
        end
      end
    end

    context 'transaction handling' do
      context 'when user creation fails' do
        it 'rolls back any changes and returns false' do
          referrer = create(:user)
          params = valid_params.merge(referral_code: referrer.referral_code)

          # Stub save methods after creating the referrer
          allow_any_instance_of(User).to receive(:save).and_return(false)
          allow_any_instance_of(User).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(User.new))

          expect {
            result = described_class.new(params).call
            expect(result).to be_falsey
          }.not_to change { [User.count, referrer.reload.reward_count] }
        end
      end

      context 'when reward count update fails' do
        it 'rolls back user creation and returns false' do
          referrer = create(:user)
          params = valid_params.merge(referral_code: referrer.referral_code)

          # Stub increment! after creating the referrer
          allow_any_instance_of(User).to receive(:increment!).and_raise(ActiveRecord::RecordInvalid.new(User.new))

          expect {
            result = described_class.new(params).call
            expect(result).to be_falsey
          }.not_to change(User, :count)
        end
      end
    end
  end
end 