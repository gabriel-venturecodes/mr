class Analysis < ApplicationRecord
  belongs_to :user
  belongs_to :conversation, optional: true
  has_many :hypotheses, dependent: :destroy

  enum :status, {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed'
  }

  validates :brief, presence: true
  validates :progress, inclusion: { in: 0..100 }

  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }

  def processing?
    status == 'processing'
  end

  def completed?
    status == 'completed'
  end

  def failed?
    status == 'failed'
  end

  def insights_count
    # Use the ActiveRecord association if available, otherwise JSON
    if hypotheses.loaded? || hypotheses.exists?
      hypotheses.count
    else
      self[:hypotheses]&.count || 0
    end
  end

  def has_multiple_insights?
    insights_count > 1
  end
  
  # Helper method to get hypotheses data from JSON for display
  def hypothesis_data
    self[:hypotheses] || []
  end
end
