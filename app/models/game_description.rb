# == Schema Information
#
# Table name: game_descriptions
#
#  id         :integer         not null, primary key
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

class GameDescription < ActiveRecord::Base
  has_many :games
end
