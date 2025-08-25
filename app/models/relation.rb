class Relation < ApplicationRecord
  belongs_to :src_entity, class_name: 'Entity'
  belongs_to :dst_entity, class_name: 'Entity'

  validates :relation_type, presence: true
  validates :confidence, presence: true, numericality: { in: 0.0..1.0 }
  validates :source_chunk_ids, presence: true
  validates :prompt_version, :model_id, :input_hash, presence: true

  RELATION_TYPES = %w[
    likes dislikes rated_highly_by criticized_for correlates_with
    led_to increases decreases
  ].freeze
  validates :relation_type, inclusion: { in: RELATION_TYPES }

  scope :by_type, ->(type) { where(relation_type: type) }
  scope :high_confidence, -> { where('confidence >= ?', 0.7) }

  def source_chunks
    Chunk.where(id: source_chunk_ids)
  end
end
