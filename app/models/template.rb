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
	before_save :set_defaults

	def set_defaults
		self.tile_count ||= 6
	end

	def board_area
		self.width * self.height
	end

	@@default_functions = {
		:hotel_size 		=> Proc.new { |level, index| (index < 5 ) ? (2 + index) : (1 + (index - 4) * 10) },
		:stock_cost 		=> Proc.new { |level, index| (200 + level * 100) + 100 * index },
		:majority_bonus 	=> Proc.new { |level, index| (2000 + level * 1000) + 1000 * index },
		:minority_bonus 	=> Proc.new { |level, index| (1000 + level * 500) + 500 * index }
	}

	# TODO: serialize this into the databas and convert to active record callback
	def pricing_table(column_functions = nil) 
	 
		column_functions.merge! @@default_functions do 
			|key, parameter, default| parameter 
		end

		Hash.new.tap do |pricing_table|
			[:low, :mid, :high].each_with_index do |level_key, level| # TODO: allow for customizable number of levels
				pricing_table[level_key] = pricing_level(level, column_functions)
			end
		end
  
	end

	def pricing_level(level, column_functions)
		Array.new.tap do |level_array|
			9.times do |tier| # TODO: replace '9' with a tier_count, add to model
				level_array[tier] = { 
					:hotel_size => column_functions[:hotel_size].call(level, tier),
					:stock_cost => column_functions[:stock_cost].call(level, tier), 
					:majority_bonus => column_functions[:majority_bonus].call(level, tier), 
					:minority_bonus => column_functions[:minority_bonus].call(level, tier)
				}
			end
		end
	end

end
