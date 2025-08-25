class Entity < ApplicationRecord
  has_many :src_relations, class_name: 'Relation', foreign_key: 'src_entity_id'
  has_many :dst_relations, class_name: 'Relation', foreign_key: 'dst_entity_id'

  validates :name, presence: true
  validates :entity_type, presence: true
  validates :canonical_key, presence: true, uniqueness: { scope: :entity_type }

  ENTITY_TYPES = %w[Company Product Demographic Attribute Campaign Metric].freeze
  validates :entity_type, inclusion: { in: ENTITY_TYPES }

  scope :by_type, ->(type) { where(entity_type: type) }

  def all_relations
    Relation.where('src_entity_id = ? OR dst_entity_id = ?', id, id)
  end
end
