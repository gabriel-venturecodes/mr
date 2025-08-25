class Hypothesis < ApplicationRecord
  has_many :claims, dependent: :destroy

  validates :title, presence: true
  validates :summary, presence: true
  validates :status, presence: true

  enum :status, {
    draft: 'draft',
    verified: 'verified',
    rejected: 'rejected',
    needs_evidence: 'needs_evidence'
  }

  scope :verified, -> { where(status: 'verified') }

  def verified_claims
    claims.where(status: 'verified')
  end

  def rejected_claims
    claims.where(status: 'rejected')
  end
end
