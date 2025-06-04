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

ActiveRecord::Schema[8.0].define(version: 2025_06_04_162412) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.integer "sla_hours"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fault_events", force: :cascade do |t|
    t.integer "id_from_source"
    t.bigint "customer_id", null: false
    t.bigint "location_asset_id", null: false
    t.integer "connector_id"
    t.datetime "fault_time"
    t.datetime "resolved_at"
    t.string "status"
    t.string "downtime_type"
    t.string "fault_type"
    t.string "source"
    t.boolean "is_alarm"
    t.datetime "processed_at"
    t.text "actions_taken"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "urgency_level"
    t.integer "response_time_hours"
    t.boolean "station_wide"
    t.index ["customer_id"], name: "index_fault_events_on_customer_id"
    t.index ["location_asset_id"], name: "index_fault_events_on_location_asset_id"
  end

  create_table "location_assets", force: :cascade do |t|
    t.string "name"
    t.bigint "location_id", null: false
    t.bigint "customer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_location_assets_on_customer_id"
    t.index ["location_id"], name: "index_location_assets_on_location_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "name"
    t.bigint "customer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_locations_on_customer_id"
  end

  add_foreign_key "fault_events", "customers"
  add_foreign_key "fault_events", "location_assets"
  add_foreign_key "location_assets", "customers"
  add_foreign_key "location_assets", "locations"
  add_foreign_key "locations", "customers"
end
