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

ActiveRecord::Schema.define(:version => 20110821190926) do

  create_table "games", :force => true do |t|
    t.string   "board"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "hotels", :force => true do |t|
    t.integer  "stock"
    t.integer  "size"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "quality"
    t.integer  "game_id"
  end

  add_index "hotels", ["game_id"], :name => "index_hotels_on_game_id"

  create_table "moves", :force => true do |t|
    t.string   "type"
    t.string   "contents"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "game_id"
  end

  add_index "moves", ["game_id"], :name => "index_moves_on_game_id"

  create_table "players", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "cash"
    t.string   "stock"
    t.integer  "user_id"
    t.integer  "game_id"
  end

  add_index "players", ["game_id"], :name => "index_players_on_game_id"
  add_index "players", ["user_id", "game_id"], :name => "index_players_on_user_id_and_game_id", :unique => true
  add_index "players", ["user_id"], :name => "index_players_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "encrypted_password"
    t.string   "salt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_online"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true

end
