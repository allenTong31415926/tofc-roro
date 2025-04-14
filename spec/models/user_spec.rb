# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid_email').for(:email) }
    it { should validate_uniqueness_of(:referral_code) }
    it { should validate_numericality_of(:reward_count).is_greater_than_or_equal_to(0) }

    context 'when email format is invalid' do
      it 'is invalid' do
        user = build(:user, email: 'invalid_email')
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include('is invalid')
      end
    end

    context 'when trying to refer self' do
      it 'is invalid' do
        user = create(:user)
        user.referred_by = user
        expect(user).not_to be_valid
        expect(user.errors[:referred_by]).to include("can't refer yourself")
      end
    end
  end

  describe 'associations' do
    it { should belong_to(:referred_by).class_name('User').optional }
    it { should have_many(:referrals).class_name('User').with_foreign_key(:referred_by_id) }
  end

  describe 'callbacks' do
    describe '#generate_referral_code' do
      let(:user) { build(:user, referral_code: nil) }

      it 'generates a referral code before create' do
        expect { user.save! }.to change(user, :referral_code).from(nil)
      end

      it 'generates an 8-character uppercase alphanumeric code' do
        user.save!
        expect(user.referral_code).to match(/^[A-Z0-9]{8}$/)
      end

      it 'ensures unique referral codes' do
        existing_user = create(:user)
        allow(SecureRandom).to receive(:alphanumeric).and_return(existing_user.referral_code, 'NEWCODE12')
        
        new_user = create(:user, referral_code: nil)
        expect(new_user.referral_code).to eq('NEWCODE12')
      end

      context 'when referral code is provided' do
        let(:user) { build(:user, referral_code: 'CUSTOM123') }

        it 'keeps the provided referral code' do
          user.save!
          expect(user.referral_code).to eq('CUSTOM123')
        end
      end
    end
  end

  describe 'referral relationships' do
    it 'allows multiple levels of referrals' do
      user1 = create(:user)
      user2 = create(:user, referred_by: user1)
      user3 = create(:user, referred_by: user2)

      expect(user2.referred_by).to eq(user1)
      expect(user3.referred_by).to eq(user2)
      expect(user1.referrals).to include(user2)
      expect(user2.referrals).to include(user3)
    end
  end

  describe 'enum behavior' do
    let(:user) { create(:user) }

    it 'defines reward status enum' do
      should define_enum_for(:reward_status).with_values(bronze: 0, silver: 1, gold: 2)
    end

    it 'provides status check methods' do
      expect(user).to respond_to(:bronze?)
      expect(user).to respond_to(:silver?)
      expect(user).to respond_to(:gold?)
    end

    it 'provides status scopes' do
      expect(User).to respond_to(:bronze)
      expect(User).to respond_to(:silver)
      expect(User).to respond_to(:gold)
    end
  end

  describe 'constants' do
    it 'defines correct reward thresholds' do
      expect(User::REWARD_THRESHOLDS).to eq({
        bronze: { min: 1, max: 4 },
        silver: { min: 5, max: 9 },
        gold: { min: 10, max: Float::INFINITY }
      }.freeze)
    end
  end
end 