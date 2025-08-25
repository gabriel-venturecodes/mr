class Chunk < ApplicationRecord
  belongs_to :document
  has_many :relations, foreign_key: 'source_chunk_ids', primary_key: 'id'
  has_many :claims, foreign_key: 'citation_chunk_ids', primary_key: 'id'

  validates :text, presence: true
  validates :chunk_hash, presence: true, uniqueness: { scope: :document_id }
  validates :position, presence: true

  before_validation :generate_chunk_hash, if: -> { text.present? && chunk_hash.blank? }

  def embedding
    return nil if embedding_json.blank?
    JSON.parse(embedding_json)
  end

  def embedding=(vector_array)
    self.embedding_json = vector_array.to_json
  end

  private

  def generate_chunk_hash
    self.chunk_hash = Digest::SHA256.hexdigest("#{document_id}-#{text}-#{position}")
  end
end
