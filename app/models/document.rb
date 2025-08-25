class Document < ApplicationRecord
  has_many :chunks, dependent: :destroy

  validates :title, presence: true
  validates :mime_type, presence: true
  validates :processing_status, presence: true

  enum :processing_status, {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed'
  }

  scope :completed, -> { where(processing_status: 'completed') }
end
