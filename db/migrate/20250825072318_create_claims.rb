class CreateClaims < ActiveRecord::Migration[8.0]
  def change
    create_table :claims do |t|
      t.references :hypothesis, null: false, foreign_key: true
      t.text :text
      t.string :status
      t.integer :citation_chunk_ids, array: true, default: []
      t.decimal :max_citation_similarity
      t.text :explanation
      t.string :prompt_version
      t.string :model_id
      t.string :input_hash

      t.timestamps
    end
    add_index :claims, :status
    add_index :claims, :citation_chunk_ids, using: :gin
  end
end
