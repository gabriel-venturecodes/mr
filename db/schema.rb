# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_26_074536) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "analyses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "brief"
    t.string "status"
    t.integer "progress"
    t.text "status_message"
    t.json "hypotheses"
    t.text "error_message"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "conversation_id"
    t.index ["conversation_id"], name: "index_analyses_on_conversation_id"
    t.index ["user_id"], name: "index_analyses_on_user_id"
  end

  create_table "chunks", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.text "text"
    t.string "chunk_hash"
    t.integer "position"
    t.jsonb "meta"
    t.text "embedding_json"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chunk_hash"], name: "index_chunks_on_chunk_hash"
    t.index ["document_id", "chunk_hash"], name: "index_chunks_on_document_id_and_chunk_hash", unique: true
    t.index ["document_id"], name: "index_chunks_on_document_id"
  end

  create_table "claims", force: :cascade do |t|
    t.bigint "hypothesis_id", null: false
    t.text "text"
    t.string "status"
    t.integer "citation_chunk_ids", default: [], array: true
    t.decimal "max_citation_similarity"
    t.text "explanation"
    t.string "prompt_version"
    t.string "model_id"
    t.string "input_hash"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["citation_chunk_ids"], name: "index_claims_on_citation_chunk_ids", using: :gin
    t.index ["hypothesis_id"], name: "index_claims_on_hypothesis_id"
    t.index ["status"], name: "index_claims_on_status"
  end

  create_table "conversation_messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.string "message_type"
    t.json "content"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_conversation_messages_on_conversation_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title"
    t.string "status"
    t.json "context"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_conversations_on_user_id"
  end

  create_table "documents", force: :cascade do |t|
    t.string "title"
    t.string "source_uri"
    t.string "mime_type"
    t.jsonb "meta"
    t.string "processing_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["processing_status"], name: "index_documents_on_processing_status"
  end

  create_table "entities", force: :cascade do |t|
    t.string "name"
    t.string "entity_type"
    t.string "canonical_key"
    t.jsonb "meta"
    t.string "prompt_version"
    t.string "model_id"
    t.string "input_hash"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["canonical_key"], name: "index_entities_on_canonical_key"
    t.index ["entity_type", "canonical_key"], name: "index_entities_on_entity_type_and_canonical_key", unique: true
    t.index ["entity_type", "name"], name: "index_entities_on_entity_type_and_name"
    t.index ["entity_type"], name: "index_entities_on_entity_type"
  end

  create_table "entity_aliases", force: :cascade do |t|
    t.string "entity_type"
    t.string "variant"
    t.string "canonical_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entity_type"], name: "index_entity_aliases_on_entity_type"
  end

  create_table "entity_merge_logs", force: :cascade do |t|
    t.string "original"
    t.string "normalized"
    t.string "merged_into"
    t.decimal "similarity"
    t.string "entity_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "hypotheses", force: :cascade do |t|
    t.string "title"
    t.text "summary"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "audit_trail"
    t.bigint "analysis_id"
    t.index ["analysis_id"], name: "index_hypotheses_on_analysis_id"
    t.index ["status"], name: "index_hypotheses_on_status"
  end

  create_table "relations", force: :cascade do |t|
    t.bigint "src_entity_id", null: false
    t.bigint "dst_entity_id", null: false
    t.string "relation_type"
    t.decimal "confidence"
    t.integer "source_chunk_ids", default: [], array: true
    t.string "prompt_version"
    t.string "model_id"
    t.string "input_hash"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "meta"
    t.index ["dst_entity_id"], name: "index_relations_on_dst_entity_id"
    t.index ["relation_type"], name: "index_relations_on_relation_type"
    t.index ["source_chunk_ids"], name: "index_relations_on_source_chunk_ids", using: :gin
    t.index ["src_entity_id", "dst_entity_id", "relation_type"], name: "idx_on_src_entity_id_dst_entity_id_relation_type_69ec4f8f41"
    t.index ["src_entity_id"], name: "index_relations_on_src_entity_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "analyses", "conversations"
  add_foreign_key "analyses", "users"
  add_foreign_key "chunks", "documents"
  add_foreign_key "claims", "hypotheses"
  add_foreign_key "conversation_messages", "conversations"
  add_foreign_key "conversations", "users"
  add_foreign_key "hypotheses", "analyses"
  add_foreign_key "relations", "entities", column: "dst_entity_id"
  add_foreign_key "relations", "entities", column: "src_entity_id"
end
