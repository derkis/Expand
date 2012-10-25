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
	attr_accessible :game_id, :player_id, :number, :board, :tiles, :data, :action

	# CONSTANTS
	INACTIVE				= 000
	PLACE_PIECE 		= 100
	START_COMPANY 		= 200
	PURCHASE_STOCK		= 300
	TRADE_STOCK			= 400
	MERGE_ORDER			= 500

	PIECE_PLACED 		= 0
	COMPANY_STARTED 	= 1
	MERGE_STARTED 		= 2

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
		
		data['players'] = []

		game.players.each_with_index do |p, i|
		  	data['players'][i] = {:stock_count => [0,0,0,0,0,0], :money => 1500}
		end

	   # Setup pricing / value levels for the 3 types of companies
	   level1 = [	{:size => 2, :cost => 200, :bonus_maj => 2000, :bonus_min => 1000},
	    			{:size => 3, :cost => 300, :bonus_maj => 3000, :bonus_min => 1500},
	    			{:size => 4, :cost => 400, :bonus_maj => 4000, :bonus_min => 2000},
	    			{:size => 5, :cost => 500, :bonus_maj => 5000, :bonus_min => 2500},
	    			{:size => 6, :cost => 600, :bonus_maj => 6000, :bonus_min => 3000},
	    			{:size => 11, :cost => 700, :bonus_maj => 7000, :bonus_min => 3500},
	    			{:size => 21, :cost => 800, :bonus_maj => 8000, :bonus_min => 4000},
	    			{:size => 31, :cost => 900, :bonus_maj => 9000, :bonus_min => 4500},
	    			{:size => 41, :cost => 1000, :bonus_maj => 10000, :bonus_min => 5000}]

	   level2 = [	{:size => 2, :cost => 300, :bonus_maj => 3000, :bonus_min => 1500},
	    			{:size => 3, :cost => 400, :bonus_maj => 4000, :bonus_min => 2000},
	    			{:size => 4, :cost => 500, :bonus_maj => 5000, :bonus_min => 2500},
	    			{:size => 5, :cost => 600, :bonus_maj => 6000, :bonus_min => 3000},
	    			{:size => 6, :cost => 700, :bonus_maj => 7000, :bonus_min => 3500},
	    			{:size => 11, :cost => 800, :bonus_maj => 8000, :bonus_min => 4000},
	    			{:size => 21, :cost => 900, :bonus_maj => 9000, :bonus_min => 4500},
	    			{:size => 31, :cost => 1000, :bonus_maj => 10000, :bonus_min => 5000},
	    			{:size => 41, :cost => 1100, :bonus_maj => 11000, :bonus_min => 5500}]

	   level3 = [	{:size => 2, :cost => 400, :bonus_maj => 4000, :bonus_min => 2000},
	    			{:size => 3, :cost => 500, :bonus_maj => 5000, :bonus_min => 2500},
	    			{:size => 4, :cost => 600, :bonus_maj => 6000, :bonus_min => 3000},
	    			{:size => 5, :cost => 700, :bonus_maj => 7000, :bonus_min => 3500},
	    			{:size => 6, :cost => 800, :bonus_maj => 8000, :bonus_min => 4000},
	    			{:size => 11, :cost => 900, :bonus_maj => 9000, :bonus_min => 4500},
	    			{:size => 21, :cost => 1000, :bonus_maj => 10000, :bonus_min => 5000},
	    			{:size => 31, :cost => 1100, :bonus_maj => 11000, :bonus_min => 5500},
	    			{:size => 41, :cost => 1200, :bonus_maj => 12000, :bonus_min => 6000}]

	    data["companies"] = {:l =>
	    						{:abbr => "l", :name => "Luxor", :stock_count => 25, :value => level1, :color => "#DE5D35", :size =>0},
	    					 :t =>
	    						{:abbr => "t", :name => "Tower", :stock_count => 25, :value => level1, :color => "#D9E043", :size =>0},
	    					 :a =>
	    						{:abbr => "a", :name => "American", :stock_count => 25, :value => level2, :color => "#3838F2", :size =>0},
	    					 :w =>
	    						{:abbr => "w", :name => "Worldwide", :stock_count => 25, :value => level2, :color => "#5E3436", :size =>0},
	    					 :f =>
	    						{:abbr => "f", :name => "Festival", :stock_count => 25, :value => level2, :color => "#44AB41", :size =>0},
	    					 :i =>
	    						{:abbr => "i", :name => "Imperial", :stock_count => 25, :value => level3, :color => "#ED47C4", :size =>0},
	    					 :c =>
	    						{:abbr => "c", :name => "Continental", :stock_count => 25, :value => level3, :color => "#24BFA5", :size =>0}
	    					}
	   
	    data["state"] = PLACE_PIECE;
	    data["active_player_id"] = starting_player_id;

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

	def data_hash
		ActiveSupport::JSON.decode(data)
	end

	def serialize_data_hash(new_data_hash)
		self.update_attributes(:data => ActiveSupport::JSON.encode(new_data_hash))
	end

	def get_company(company_abbr)
		companies = data_hash["companies"]
		companies.each do |company|
			return company if company["abbr"] == company_abbr
		end
	end

	def company_started(company_abbr)		
		return true if get_company(company_abbr)["size"] > 0
		return false
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

	def get_tile_at(row, column)
		{
			:row => row,
			:column => column,
			:index => row * game.template.width + column,
			:tile => board[row * game.template.width + column],
			:key => row.to_s + "_" + column.to_s
		}
	end

	def get_tile_at(row, column)
		board[row * game.template.width + column]
	end

	def piece_index(row, column)
		row * game.template.width + column
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
		pieces[0] = (piece_index % self.game.template.width != 0) ? board[piece_index - 1] : nil
		# Right
		pieces[1] = (piece_index % self.game.template.width != self.game.template.width - 1) ? board[piece_index + 1] : nil
		# Top
		pieces[2] = (piece_index >= self.game.template.width) ? board[piece_index - self.game.template.width] : nil
		# Bottom
		pieces[3] = (piece_index / self.game.template.width < self.game.template.height - 1) ? board[piece_index + self.game.template.width] : nil

		pieces
	end

	# -----------------------------------------------------------------
	# Returns true if the tile has an adjacent tile that exists in the 
	# provided hash
	# -----------------------------------------------------------------
	def has_adjacent(piece_index, types)
		pieces = get_adjacent_pieces(piece_index)
		[0,1,2,3].each do |i|
			return true if types.include?(pieces[i].to_sym)
		end
		return false
	end

	# -----------------------------------------------------------------
	# Places a piece on the board for this turn only.
	#
	# Returns "CREATE_COMPANY" if possible given the placed piece.
	# -----------------------------------------------------------------
	def place_piece (row, column)
		new_board = self.board.dup
		piece_index = self.piece_index(row, column);
		new_board[piece_index] = "u"

		self.update_attributes(:board => new_board)

	 	return COMPANY_STARTED if has_adjacent(piece_index, Set.new([:u]))
	 	return PIECE_PLACED
	end

	# -----------------------------------------------------------------
	# Returns all the cells connected to row,column that are not "e" cells
	# -----------------------------------------------------------------
	def get_connected_tiles(row, column)
	    get_connected_cells_recurse(row, column, {});
	end

	def get_connected_tiles_recurse(row, column, map)
	    left = column > 0 ? get_tile_at(row, column - 1) : nil;
	    right = column < game.template.width - 1 ? get_tile_at(row, column + 1) : nil;
	    top = row > 0 ? get_tile_at(row - 1, column) : nil;
	    bottom = row < game.template.height - 1 ? get_tile_at(row + 1, column) : nil;

	    [left, right, top, bottom].each do |item|
	        if item && item.tile != "e" && !map.has_key(item.key)
	            map[item.key] = item;
	            get_connected_tiles_recurse(item.row, item.column, map);
	        end
	    end
	    map
	end

	# -----------------------------------------------------------------
	# Starts a company of all cells connected to the provided row, column
	# -----------------------------------------------------------------
	def start_company(row, column, company_abbr)
		tiles = get_connected_tiles(row, column)

		tiles.each do |t|
			board[t.index] = company_abbr
		end

		update_attributes(:board => board.dup)

		data_hash["companies"][company_abbr]["size"] = tiles.size
	end
end
