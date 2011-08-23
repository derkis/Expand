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
  attr_accessible :user_id
  serialize :stock
  
  after_create :init_defaults
  
  def init_defaults
    cash = 6000
    stock = Array.new(7, 0)
  end
end
