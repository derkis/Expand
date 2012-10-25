# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
Template.create(:id => 1, :height => 9,:width => 12, :stock_count => 25, :tile_count => 6)
User.create(:email => "p1@test.com", :password => "password", :password_confirmation => "password")
User.create(:email => "p2@test.com", :password => "password", :password_confirmation => "password")
User.create(:email => "p3@test.com", :password => "password", :password_confirmation => "password")
User.create(:email => "p4@test.com", :password => "password", :password_confirmation => "password")