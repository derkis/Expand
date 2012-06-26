# == Schema Information
#
# Table name: players
#
#  id         :integer         not null, primary key
#  created_at :datetime        not null
#  updated_at :datetime        not null
#  game_id    :integer
#  user_id    :integer
#  accepted   :boolean
#

class Player < ActiveRecord::Base
  belongs_to :user
  belongs_to :game
  
  attr_accessible :user_id, :game_id, :accepted
  
end
