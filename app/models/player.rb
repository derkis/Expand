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
#  tiles      :string(255)
#

class Player < ActiveRecord::Base
  
  after_create :create_defaults

  belongs_to :user
  belongs_to :game
  has_many :turns

  attr_accessible :user_id, :game_id, :accepted

  def is_active
    game.cur_turn.player_id == id
  end
  
  def create_defaults
    self.accepted ||= false
  end

  def to_s
    "#{self.id}, game_id: #{self.game_id}, user_id: #{self.user_id}, accepted: #{self.accepted}"
  end
  
end
