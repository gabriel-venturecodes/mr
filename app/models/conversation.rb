class Conversation < ApplicationRecord
  belongs_to :user
  has_many :conversation_messages, dependent: :destroy
  has_many :analyses, dependent: :destroy

  enum :status, {
    active: 'active',
    archived: 'archived',
    completed: 'completed'
  }

  validates :title, presence: true

  scope :recent, -> { order(updated_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }

  def last_message
    conversation_messages.order(created_at: :desc).first
  end

  def insights_count
    conversation_messages.where(message_type: 'insight').count
  end

  def current_insight
    # Get the insight the user is currently exploring
    context&.dig('current_insight_id')
  end

  def available_insights
    # Get all insights that haven't been explored yet
    conversation_messages.where(message_type: 'insight')
                         .where.not(id: current_insight)
  end

  def set_current_insight(insight_id)
    self.context ||= {}
    self.context['current_insight_id'] = insight_id
    save!
  end
end
