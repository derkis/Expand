# == Schema Information
#
# Table name: moves
#
#  id         :integer         not null, primary key
#  type       :string(255)
#  contents   :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Move < ActiveRecord::Base
  belongs_to :game
  belongs_to :player
  
  serialize :contents
end
