class Claim < ApplicationRecord
  belongs_to :hypothesis

  validates :text, presence: true
  validates :citation_chunk_ids, presence: true
  validates :status, presence: true
  validates :prompt_version, :model_id, :input_hash, presence: true

  enum :status, {
    pending: 'pending',
    verified: 'verified',
    rejected: 'rejected',
    needs_evidence: 'needs_evidence'
  }

  scope :verified, -> { where(status: 'verified') }
  scope :rejected, -> { where(status: 'rejected') }

  def cited_chunks
    Chunk.where(id: citation_chunk_ids)
  end

  def primary_source_document
    cited_chunks.joins(:document).first&.document&.title
  end
end
