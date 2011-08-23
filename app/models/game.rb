# == Schema Information
#
# Table name: games
#
#  id         :integer         not null, primary key
#  board      :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Game < ActiveRecord::Base
  attr_accessible :board, :hotels
  
  has_many :players
  has_many :hotels
  has_many :moves
  has_many :users, :through => :players
  
  accepts_nested_attributes_for :players, :allow_destroy => true
  
end
