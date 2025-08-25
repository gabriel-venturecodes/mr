class CreateEntities < ActiveRecord::Migration[8.0]
  def change
    create_table :entities do |t|
      t.string :name
      t.string :entity_type
      t.string :canonical_key
      t.jsonb :meta
      t.string :prompt_version
      t.string :model_id
      t.string :input_hash

      t.timestamps
    end
    add_index :entities, :entity_type
    add_index :entities, :canonical_key
    add_index :entities, [:entity_type, :name]
    add_index :entities, [:entity_type, :canonical_key], unique: true
  end
end
