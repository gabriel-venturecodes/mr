class CreateConversationMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :conversation_messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.string :message_type
      t.json :content
      t.json :metadata

      t.timestamps
    end
  end
end
