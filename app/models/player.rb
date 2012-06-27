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
  after_initialize :init
  
  belongs_to :user
  belongs_to :game
  
  attr_accessible :user_id, :game_id, :accepted
  
  def init
    self.accepted = false
  end
  
end
