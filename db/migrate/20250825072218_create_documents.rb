class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.string :title
      t.string :source_uri
      t.string :mime_type
      t.jsonb :meta
      t.string :processing_status

      t.timestamps
    end
    add_index :documents, :processing_status
  end
end
