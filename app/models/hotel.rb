# == Schema Information
#
# Table name: hotels
#
#  id         :integer         not null, primary key
#  stock      :integer
#  size       :integer
#  created_at :datetime
#  updated_at :datetime
#  name       :string(255)
#  quality    :string(255)
#  game_id    :integer
#

class Hotel < ActiveRecord::Base
  attr_accessible :name, :quality, :stock, :size
  
end
