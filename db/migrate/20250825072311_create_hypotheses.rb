class CreateHypotheses < ActiveRecord::Migration[8.0]
  def change
    create_table :hypotheses do |t|
      t.string :title
      t.text :summary
      t.string :status

      t.timestamps
    end
    add_index :hypotheses, :status
  end
end
