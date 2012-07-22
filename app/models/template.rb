# == Schema Information
#
# Table name: templates
#
#  id          :integer         not null, primary key
#  created_at  :datetime        not null
#  updated_at  :datetime        not null
#  width       :integer
#  height      :integer
#  stock_count :integer
#

class Template < ActiveRecord::Base

	has_many :games

end
