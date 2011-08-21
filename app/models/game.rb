# == Schema Information
#
# Table name: games
#
#  id         :integer         not null, primary key
#  board      :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Game < ActiveRecord::Base
  attr_accessible :players
end
