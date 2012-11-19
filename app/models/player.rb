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
#  index      :integer
#

class Player < ActiveRecord::Base
  
  after_create :after_create
  after_update :after_update

  belongs_to :user
  belongs_to :game
  has_many :turns

  attr_accessible :user_id, :game_id, :accepted

  # active record callbacks
  def after_create
    self.update_attributes(:accepted => false)
  end

  def after_update
    if self.accepted_was == false and self.accepted
      self.game.player_did_accept
    end
  end

  # conditions
  def is_active
    game.current_turn.player_id == id
  end

  # convenience
  def email
    user.email
  end

  def to_s
    "#{self.id}, game_id: #{self.game_id}, user_id: #{self.user_id}, accepted: #{self.accepted}"
  end
  
end
