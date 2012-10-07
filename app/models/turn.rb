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

	# ASSOSCIATIONS
	belongs_to :game
	belongs_to :player

 	# ATTRIBUTE ACCESSORS
	attr_accessible :game_id, :player_id, :number, :board, :tiles

	# CONSTANTS
	Type = { 
		:no_action 			=> { :code => 000 },
		:place_piece    => { :code => 100 },
		:start_company	=> { :code => 200 },
		:purchase_stock => { :code => 300 },
		:trade_stock    => { :code => 400 },
		:merge_order    => { :code => 500 },
		:debug_mode     => { :code => 999 }
	}

 	# METHODS
	# creates the first turn given a game and a starting player id.
	def self.create_first_turn_for(game, starting_player_id)
		@turn = Turn.new({ :game_id => game.id, :player_id => starting_player_id })
		@turn.number = 0,
		@turn.board = 'e' * game.board_area
		@turn.refresh_player_tiles
		@turn.save!
		@turn
	end

	# redistributes all the player tiles until each player has the game allotted amount
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

	# returns a single random unused tile index
	def get_random_unused_tile
		find_unused_tile_indices.shuffle!.pop
	end

	# returns an array of indexes into the board that are unchosen tiles
	def find_unused_tile_indices
  	tiles = Array.new
  	self.board.chars.to_a.each_with_index { |c, i| tiles.push(i) if c == 'e' }
  	tiles
	end

end
