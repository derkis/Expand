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

ActiveRecord::Schema.define(:version => 20121103205429) do

  create_table "games", :force => true do |t|
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.integer  "status"
    t.integer  "template_id"
    t.integer  "proposing_player"
    t.integer  "turn_id"
  end

  create_table "players", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "game_id"
    t.integer  "user_id"
    t.boolean  "accepted"
    t.string   "tiles"
    t.integer  "index"
  end

  create_table "templates", :force => true do |t|
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "width"
    t.integer  "height"
    t.integer  "stock_count"
    t.integer  "tile_count"
    t.integer  "company_count"
    t.text     "pricing"
    t.text     "companies"
  end

  create_table "turns", :force => true do |t|
    t.integer  "game_id"
    t.integer  "player_id"
    t.integer  "number"
    t.string   "board"
    t.text     "data"
    t.text     "action"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "step"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.datetime "last_request_at"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
