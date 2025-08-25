class ConversationMessage < ApplicationRecord
  belongs_to :conversation

  enum message_type: {
    user_query: 'user_query',
    insight: 'insight',
    insight_selection: 'insight_selection',
    follow_up: 'follow_up',
    document_upload: 'document_upload',
    analysis_result: 'analysis_result'
  }

  validates :message_type, presence: true
  validates :content, presence: true

  scope :insights, -> { where(message_type: 'insight') }
  scope :user_messages, -> { where(message_type: ['user_query', 'follow_up']) }
  scope :recent, -> { order(created_at: :desc) }

  def hypothesis
    # Extract hypothesis data if this is an insight message
    content&.dig('hypothesis') if insight?
  end

  def selected?
    # Check if this insight was selected by the user
    metadata&.dig('selected') == true
  end

  def mark_as_selected!
    self.metadata ||= {}
    self.metadata['selected'] = true
    self.metadata['selected_at'] = Time.current
    save!
  end
end
