class AddMetaToRelations < ActiveRecord::Migration[8.0]
  def change
    add_column :relations, :meta, :jsonb
  end
end
