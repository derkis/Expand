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
  
  after_create :create_defaults
  
  belongs_to :user
  belongs_to :game
  
  attr_accessible :user_id, :game_id, :accepted
  
  def create_defaults
    self.accepted ||= false
  end
  
  def to_s
    "#{self.id}, game_id: #{self.game_id}, user_id: #{self.user_id}, accepted: #{self.accepted}"
  end
  
end
