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

	def clone_next_turn()
		turn = Turn.new({ :game_id => game_id, :player_id => player_id, :number => number + 1, :board => board, :data => data })
		turn.save!
		turn
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

	# -----------------------------------------------------------------	
	# Returns true if a player is starting a company this turn
	# -----------------------------------------------------------------
	def is_starting_company
		if self.action != nil
			act = ActiveSupport::JSON.decode(self.action)
			return act["start_company"]
		end
		return nil
	end

	# -----------------------------------------------------------------
	# Returns a Hash of the characters of the pieces adjacent to the 
	# provided piece index. If a piece is next to the edge, that 
	# location in the Hash is nil.
	#
	# Returns {0: LEFT, 1: RIGHT, 2: TOP, 3: BOTTOM}
	# -----------------------------------------------------------------
	def get_adjacent_pieces(piece_index)
		pieces = Hash.new("e");

		# Left
		pieces[0] = piece_index % self.game.template.width != 0 ? board[piece_index - 1] : nil
		# Right
		pieces[1] = piece_index % self.game.template.width != self.game.template.width - 1 ? board[piece_index + 1] : nil
		# Top
		pieces[2] = piece_index >= self.game.template.width ? board[piece_index - self.game.template.width] : nil
		# Bottom
		pieces[3] = piece_index / self.game.template.width < self.game.template.height - 1 ? board[piece_index + - self.game.template.width] : nil

		pieces
	end

	# -----------------------------------------------------------------
	# Returns true if the tile has an adjacent tile that has been
	# placed but is not part of a hotel chain.
	# -----------------------------------------------------------------
	def has_adjacent_no_hotel_tile(adjacent_pieces)
		return true if adjacent_pieces[0] == "u"
		return true if adjacent_pieces[1] == "u"
		return true if adjacent_pieces[2] == "u"
		return true if adjacent_pieces[3] == "u"
		return false
	end

	# -----------------------------------------------------------------
	# Places a piece on the board for this turn only.
	#
	# Returns "CREATE_COMPANY" if possible given the placed piece.
	# -----------------------------------------------------------------
	def place_piece_for (row, column, player)
		ret = "NOTHING SPECIAL"

		new_board = self.board.dup
		piece_index = self.game.piece_index(row, column);
		new_board[piece_index] = 'u'

	 	# Check for new company creation
	 	adjacents = get_adjacent_pieces(piece_index);

	 	ret = "CREATE_COMPANY" if has_adjacent_no_hotel_tile(adjacents)

	 	update_attributes(:board => new_board)

	 	return ret
	end
end
