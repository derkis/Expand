# == Schema Information
#
# Table name: players
#
#  id         :integer         not null, primary key
#  created_at :datetime
#  updated_at :datetime
#  cash       :string(255)
#  stock      :string(255)
#

class Player < ActiveRecord::Base
  attr_accessible :user_id
end
