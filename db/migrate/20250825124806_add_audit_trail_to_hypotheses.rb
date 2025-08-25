class AddAuditTrailToHypotheses < ActiveRecord::Migration[8.0]
  def change
    add_column :hypotheses, :audit_trail, :json
  end
end
