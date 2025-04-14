class User < ApplicationRecord
  REWARD_THRESHOLDS = {
    bronze: { min: 1, max: 4 },
    silver: { min: 5, max: 9 },
    gold: { min: 10, max: Float::INFINITY }
  }.freeze

  enum reward_status: { bronze: 0, silver: 1, gold: 2 }

  belongs_to :referred_by, class_name: 'User', optional: true
  has_many :referrals, class_name: 'User', foreign_key: :referred_by_id

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :referral_code, uniqueness: true
  validates :reward_count, numericality: { greater_than_or_equal_to: 0 }
  validate :cannot_refer_self

  before_create :generate_referral_code

  private

  def cannot_refer_self
    if referred_by_id.present? && referred_by_id == id
      errors.add(:referred_by, "can't refer yourself")
    end
  end

  def generate_referral_code
    return if referral_code.present?
    
    loop do
      self.referral_code = SecureRandom.alphanumeric(8).upcase
      break unless User.exists?(referral_code: referral_code)
    end
  end
end
