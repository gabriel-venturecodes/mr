class CreateChunks < ActiveRecord::Migration[8.0]
  def change
    create_table :chunks do |t|
      t.references :document, null: false, foreign_key: true
      t.text :text
      t.string :chunk_hash
      t.integer :position
      t.jsonb :meta
      t.text :embedding_json  # Store as JSON text until pgvector is available

      t.timestamps
    end
    add_index :chunks, :chunk_hash
    add_index :chunks, [:document_id, :chunk_hash], unique: true
  end
end
