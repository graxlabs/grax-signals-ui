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

ActiveRecord::Schema[7.2].define(version: 2024_11_21_235211) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "lead_score_snapshots", force: :cascade do |t|
    t.string "lead_id"
    t.integer "total_score"
    t.integer "previous_score"
    t.jsonb "dimension_scores"
    t.datetime "calculated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "scoring_run_id"
    t.index ["calculated_at"], name: "index_lead_score_snapshots_on_calculated_at"
    t.index ["lead_id"], name: "index_lead_score_snapshots_on_lead_id"
    t.index ["scoring_run_id"], name: "index_lead_score_snapshots_on_scoring_run_id"
  end

  create_table "scoring_runs", force: :cascade do |t|
    t.string "name"
    t.string "sfdc_object"
    t.text "query"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "records_scored"
    t.integer "records_updated"
    t.string "status"
    t.text "error_message"
    t.string "initiated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "full_name"
    t.string "uid"
    t.string "avatar_url"
    t.string "provider"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "lead_score_snapshots", "scoring_runs"
end
