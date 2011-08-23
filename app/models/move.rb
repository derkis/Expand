# == Schema Information
#
# Table name: moves
#
#  id         :integer         not null, primary key
#  type       :string(255)
#  contents   :string(255)
#  created_at :datetime
#  updated_at :datetime
#  game_id    :integer
#

class Move < ActiveRecord::Base
  attr_accessible :id, :contents
  serialize :contents
    
  belongs_to :game
end
