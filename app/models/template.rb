# == Schema Information
#
# Table name: templates
#
#  id            :integer         not null, primary key
#  created_at    :datetime        not null
#  updated_at    :datetime        not null
#  width         :integer
#  height        :integer
#  stock_count   :integer
#  tile_count    :integer
#  company_count :integer
#  pricing       :text
#  companies     :text
#

class Template < ActiveRecord::Base

	has_many :games

	def self.create(attributes = nil, options = {}, &block)
		attributes[:pricing] = Template.generate_pricing_table(attributes[:column_functions] || {})
		attributes[:tile_count] ||= 6
		attributes[:companies] ||= Template.default_companies
		super(attributes, options, &block)
	end

	def self.default_companies
		{
		 :l =>
			{:abbr => "l", :name => "Luxor", :stock_count => 25, :value => "low", :color => "#DE5D35", :size =>0},
		 :t =>
			{:abbr => "t", :name => "Tower", :stock_count => 25, :value => "low", :color => "#D9E043", :size =>0},
		 :a =>
			{:abbr => "a", :name => "American", :stock_count => 25, :value => "mid", :color => "#3838F2", :size =>0},
		 :w =>
			{:abbr => "w", :name => "Worldwide", :stock_count => 25, :value => "mid", :color => "#5E3436", :size =>0},
		 :f =>
			{:abbr => "f", :name => "Festival", :stock_count => 25, :value => "mid", :color => "#44AB41", :size =>0},
		 :i =>
			{:abbr => "i", :name => "Imperial", :stock_count => 25, :value => "high", :color => "#ED47C4", :size =>0},
		 :c =>
			{:abbr => "c", :name => "Continental", :stock_count => 25, :value => "high", :color => "#24BFA5", :size =>0}
		}
	end

	def board_area
		self.width * self.height
	end

	def self.generate_pricing_table(column_functions) 
	 	
	 	default_functions = {
			:hotel_size 		=> Proc.new { |level, index| (index < 5 ) ? (2 + index) : (1 + (index - 4) * 10) },
			:stock_cost 		=> Proc.new { |level, index| (200 + level * 100) + 100 * index },
			:majority_bonus 	=> Proc.new { |level, index| (2000 + level * 1000) + 1000 * index },
			:minority_bonus 	=> Proc.new { |level, index| (1000 + level * 500) + 500 * index }
		}

		column_functions.merge! default_functions do 
			|key, parameter, default| parameter 
		end

		Hash.new.tap do |pricing_table|
			[:low, :mid, :high].each_with_index do |level_key, level| # TODO: allow for customizable number of levels
				pricing_table[level_key] = Template.pricing_level(level, column_functions)
			end
		end
  
	end

	def self.pricing_level(level, column_functions)
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
