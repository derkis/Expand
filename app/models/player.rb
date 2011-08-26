# == Schema Information
#
# Table name: players
#
#  id         :integer         not null, primary key
#  created_at :datetime
#  updated_at :datetime
#  cash       :string(255)
#  stock      :string(255)
#  user_id    :integer
#  game_id    :integer
#

class Player < ActiveRecord::Base
  attr_accessible :user_id, :cash, :stock
  serialize :stock
  
  before_save :init_defaults
  
  def init_defaults
    logger.debug "  DEBUG: player::init_defaults"
    self.cash = 6000 unless self.cash
    self.stock = Array.new(7, 0) unless self.stock
  end
end
