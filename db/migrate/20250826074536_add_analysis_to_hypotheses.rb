class AddAnalysisToHypotheses < ActiveRecord::Migration[8.0]
  def change
    add_reference :hypotheses, :analysis, null: true, foreign_key: true
  end
end
