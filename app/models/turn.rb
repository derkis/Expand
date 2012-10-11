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

	# ASSOCIATIONS
	belongs_to :game
	belongs_to :player

 	# ATTRIBUTE ACCESSORS
	attr_accessible :game_id, :player_id, :number, :board, :tiles, :data

	# CONSTANTS
	Type = { 
		:no_action 		=> { :code => 000 },
		:place_piece    => { :code => 100 },
		:start_company	=> { :code => 200 },
		:purchase_stock => { :code => 300 },
		:trade_stock    => { :code => 400 },
		:merge_order    => { :code => 500 }
	}

 	# CREATION
	# creates the first turn given a game and a starting player id.
	def self.create_first_turn_for(game, starting_player_id)
		turn = Turn.new({
			:number => 0,
			:game_id => game.id, 
			:player_id => starting_player_id,  
			:board => 'e' * game.template.board_area 
		})

		turn.refresh_player_tiles

		data = Hash.new({})
		game.players.each_with_index do |p, i|
	      data[i] = {:stock_count => [0,0,0,0,0,0], :money => 1500}
	    end
	    turn.data = ActiveSupport::JSON.encode(data)

		turn if turn.save!
	end

	# creates subsequent turn from the this turn
	def create_next_turn_with_player(player)
		Turn.create({ 
			:number => number + 1, 
			:game_id => self.game_id, 
			:player_id => player.id, 
			:board => self.board, 
			:data => data
		})
	end

	def data_object
		ActiveSupport::JSON.decode(data)
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

		newBoard = self.board.dup;

		self.game.players.each_with_index do |p, pid|
			while tile_counts[pid] < game.template.tile_count  
				ix = unused_tiles.pop
				puts ix.to_s
				newBoard[ix] = pid.to_s
				tile_counts[pid] += 1
			end
		end

		self.board = newBoard;
	end

	def get_random_unused_tile
		find_unused_tile_indices.shuffle!.pop
	end

	# returns an array of indexes into the board that are unchosen tiles
	def find_unused_tile_indices
	  	tiles = Array.new
	  	self.board.chars.to_a.each_with_index { |c, i| tiles.push(i) if c == 'e' }
	  	tiles
	end

	def place_piece_for(row, column, player)
		new_board = self.board.dup
		new_board[self.game.piece_index(row, column)] = 'u'
		update_attributes(:board => new_board)
	end
end
