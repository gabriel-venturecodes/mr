class AddConversationToAnalyses < ActiveRecord::Migration[8.0]
  def change
    add_reference :analyses, :conversation, null: true, foreign_key: true
  end
end
