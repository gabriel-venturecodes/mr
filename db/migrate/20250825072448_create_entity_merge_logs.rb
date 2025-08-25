class CreateEntityMergeLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :entity_merge_logs do |t|
      t.string :original
      t.string :normalized
      t.string :merged_into
      t.decimal :similarity
      t.string :entity_type

      t.timestamps
    end
  end
end
