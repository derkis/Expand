# == Schema Information
#
# Table name: hotels
#
#  id         :integer         not null, primary key
#  stock      :integer
#  size       :integer
#  created_at :datetime
#  updated_at :datetime
#

class Hotel < ActiveRecord::Base
end
