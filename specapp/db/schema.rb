# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100726160133) do

  create_table "companies", :force => true do |t|
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.string   "name",              :null => false
    t.string   "city"
    t.string   "street"
    t.string   "zip"
    t.boolean  "is_active"
    t.datetime "registration_date"
    t.integer  "location_id"
    t.integer  "group_id"
    t.integer  "object_1_id"
    t.string   "object_1_type"
    t.integer  "object_2_id"
    t.string   "object_2_type"
    t.integer  "polyref_1_id"
    t.string   "polyref_1_type"
    t.integer  "polyref_2_id"
    t.string   "polyref_2_type"
  end

  create_table "company_bars", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "name"
  end

  create_table "company_foos", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "name"
  end

  create_table "company_locations", :force => true do |t|
    t.float  "lat"
    t.float  "lon"
    t.string "raw_name"
  end

  create_table "company_phones", :force => true do |t|
    t.integer "company_id"
    t.string  "number"
  end

  create_table "contacts", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "field"
    t.string   "value"
  end

  create_table "external_object_bars", :force => true do |t|
    t.string "name"
  end

  create_table "external_object_foos", :force => true do |t|
    t.string "name"
  end

  create_table "groups", :force => true do |t|
    t.string "name"
  end

  create_table "ownable_object_bars", :force => true do |t|
    t.string  "name"
    t.integer "owner_id"
  end

  create_table "ownable_object_foos", :force => true do |t|
    t.string  "name"
    t.integer "owner_id"
  end

  create_table "users", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "name"
    t.integer  "company_id"
  end

end
