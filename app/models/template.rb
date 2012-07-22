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
#  tile_count  :integer
#

class Template < ActiveRecord::Base

	has_many :games
	before_save :before_save_handler

	def before_save_handler
		self.tile_count ||= 6
	end

end
