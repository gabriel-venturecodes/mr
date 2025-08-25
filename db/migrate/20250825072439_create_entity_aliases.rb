class CreateEntityAliases < ActiveRecord::Migration[8.0]
  def change
    create_table :entity_aliases do |t|
      t.string :entity_type
      t.string :variant
      t.string :canonical_name

      t.timestamps
    end
    add_index :entity_aliases, :entity_type
  end
end
