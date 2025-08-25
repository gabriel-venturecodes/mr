class CreateAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :analyses do |t|
      t.references :user, null: false, foreign_key: true
      t.text :brief
      t.string :status
      t.integer :progress
      t.text :status_message
      t.json :hypotheses
      t.text :error_message
      t.datetime :completed_at

      t.timestamps
    end
  end
end
