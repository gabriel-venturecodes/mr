class CreateRelations < ActiveRecord::Migration[8.0]
  def change
    create_table :relations do |t|
      t.references :src_entity, null: false, foreign_key: { to_table: :entities }
      t.references :dst_entity, null: false, foreign_key: { to_table: :entities }
      t.string :relation_type
      t.decimal :confidence
      t.integer :source_chunk_ids, array: true, default: []
      t.string :prompt_version
      t.string :model_id
      t.string :input_hash

      t.timestamps
    end
    add_index :relations, :relation_type
    add_index :relations, [:src_entity_id, :dst_entity_id, :relation_type]
    add_index :relations, :source_chunk_ids, using: :gin
  end
end
