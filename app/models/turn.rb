# == Schema Information
#
# Table name: turns
#
#  id         :integer         not null, primary key
#  game_id    :integer
#  player_id  :integer
#  number     :integer
#  board      :string(255)
#  data       :text
#  action     :text
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

class Turn < ActiveRecord::Base

	#####################################################
 	# Callbacks
  	#####################################################
	belongs_to :game
	belongs_to :player

	#####################################################
 	# Attribute Settings
  	#####################################################
	attr_accessible :game_id, :player_id, :number, :board, :tiles

	#####################################################
 	# Methods
  	#####################################################
  	#--------------------------------------------------
	# Creates the first turn given a game and a 
	# starting player id.
	#--------------------------------------------------
	def self.create_first_turn_for(_game, starting_player_id)
		@turn = Turn.new({:game_id => _game.id})
		@turn.player_id = starting_player_id,
		@turn.number = 0,
		@turn.board = 'e' * _game.board_area
		@turn.refresh_player_tiles
		@turn.save!
		@turn
	end

	#--------------------------------------------------
	# Redistributes all the player tiles until each
	# player has the game allotted amount
	#--------------------------------------------------
	def refresh_player_tiles
		tile_counts = Hash.new(0)

		self.board.chars.to_a.each do |t|
			pid = t.ord - 48
			if pid >= 0 && pid <= 9
				tile_counts[pid] += 1 
			end
		end

		unused_tiles = find_unused_tile_indices.shuffle!

		self.game.players.each_with_index do |p, pid|
			while tile_counts[pid] < game.template.tile_count  
				ix = unused_tiles.pop
				puts ix.to_s
				self.board[ix] = pid.to_s
				tile_counts[pid] += 1
			end
		end
	end

	#--------------------------------------------------
	# Returns a single random unused tile index
	#--------------------------------------------------
	def get_random_unused_tile
		tiles = find_unused_tile_indices.shuffle!

		tiles.pop
	end

	#--------------------------------------------------
	# Returns an array of indexes into the board
	# that are unchosen tiles
	#--------------------------------------------------
	def find_unused_tile_indices
    	tiles = Array.new
    	self.board.chars.to_a.each_with_index { |c, i| tiles.push(i) if c == 'e' }
    	tiles
  	end

end
