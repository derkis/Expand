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
#  step       :integer
#

class String
  def is_int?
    self.to_i.to_s == self
  end
end

class Turn < ActiveRecord::Base
	# ASSOCIATIONS
	belongs_to :game
	belongs_to :player

 	# ATTRIBUTE ACCESSORS
	attr_accessible :game_id, :player_id, :number, :board, :tiles, :data, :action, :step

	# CONSTANTS
	INACTIVE					= 000
	PLACE_PIECE 				= 100
	START_COMPANY 				= 200
	PURCHASE_STOCK				= 300
	TRADE_STOCK					= 400
	MERGE_CHOOSE_COMPANY 		= 500
	MERGE_CHOOSE_COMPANY_ORDER	= 520
	MERGE_CHOOSE_STOCK_OPTIONS	= 550
	GAME_OVER					= 600

	PIECE_PLACED 				= 0
	COMPANY_STARTED 			= 1
	MERGE_STARTED 				= 2

 	# CREATION
	# creates the first turn given a game and a starting player id.
	def self.create_first_turn_for(game, starting_player_id)
		turn = Turn.new({
			:number => 0,
			:step => 0,
			:game_id => game.id, 
			:player_id => starting_player_id,  
			:board => 'e' * game.template.board_area 
		})

		turn.refresh_player_tiles

		data = Hash.new({})
		
		data['players'] = []

		game.players.each_with_index do |p, i|
		  	data['players'][i] = {:stock_count => {}, :money => 6000, :index => p.index}
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
	    						{:abbr => "l", :name => "Luxor", :stock_count => 25, :value => level1, :color => "#EE6D45", :size =>0},
	    					 :t =>
	    						{:abbr => "t", :name => "Tower", :stock_count => 25, :value => level1, :color => "#E9F053", :size =>0},
	    					 :a =>
	    						{:abbr => "a", :name => "American", :stock_count => 25, :value => level2, :color => "#2828D2", :size =>0},
	    					 :w =>
	    						{:abbr => "w", :name => "Worldwide", :stock_count => 25, :value => level2, :color => "#4E2426", :size =>0},
	    					 :f =>
	    						{:abbr => "f", :name => "Festival", :stock_count => 25, :value => level2, :color => "#54BB51", :size =>0},
	    					 :i =>
	    						{:abbr => "i", :name => "Imperial", :stock_count => 25, :value => level3, :color => "#FD57D4", :size =>0},
	    					 :c =>
	    						{:abbr => "c", :name => "Continental", :stock_count => 25, :value => level3, :color => "#34CFB5", :size =>0}
	    					}
	   
	    data["stock_purchase_limit"] = 3;
	    data["state"] = PLACE_PIECE;
	    data["active_player_id"] = starting_player_id;

	    turn.data = ActiveSupport::JSON.encode(data)

		turn if turn.save!
	end

	def stock_value_for(company_abbr, what = "cost")
		company_size = data_hash["companies"][company_abbr]["size"]
		value_table = data_hash["companies"][company_abbr]["value"]

		last = 0

		value_table.each_with_index do |row, i|
			break if row["size"] > company_size
			last = i
		end

		# At this point, i - 1 in the table holds the row that contains the cost
		val = value_table[last == 0 ? 0 : last]
		return val[what]
	end

	# creates subsequent turn from the this turn
	def create_next_turn_with_player(player)
		new_data = data_hash
		new_data["state"] = PLACE_PIECE

		# We want to WIPE OUT any turn that has our destination turn number and greater. This is possible
		# because when debugging we could have stepped back through previous turns and if we play from that
		# point we want to erase any game data from that point forward.
		Turn.where("number >= ? AND game_id = ?", game.cur_turn.number + 1, game.id).destroy_all

		return Turn.create({ 
			:number => number + 1, 
			:game_id => self.game_id,
			:step => 0, 
			:player_id => player.id, 
			:board => self.board, 
			:data => ActiveSupport::JSON.encode(new_data)
		})
	end

	# creates subsequent step from the this turn
	def create_next_turn_step()
		return Turn.create({ 
			:number => self.number,
			:step => self.step + 1, 
			:game_id => self.game_id, 
			:player_id => player_id, 
			:board => self.board.dup, 
			:data => data.dup
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
		companies.each do |key, company|
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

		new_board = self.board.dup;

		self.game.players.each_with_index do |p, pid|
			while tile_counts[pid] < game.template.tile_count  
				ix = unused_tiles.pop
				puts ix.to_s
				new_board[ix] = pid.to_s
				tile_counts[pid] += 1
			end
		end

		self.update_attributes(:board => new_board)
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
			"row" => row,
			"column" => column,
			"index" => row * game.template.width + column,
			"tile" => board[row * game.template.width + column],
			"key" => row.to_s + "_" + column.to_s
		}
	end

	def piece_index(row, column)
		row * game.template.width + column
	end

	def refresh_company_sizes
		new_data_hash = data_hash
		new_data_hash["companies"].each do |key, company|
			company["size"] = 0
		end

		self.board.chars.to_a.each do |t|
			if new_data_hash["companies"].has_key? t
				new_data_hash["companies"][t]["size"] += 1
			end
		end

		serialize_data_hash(new_data_hash)
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
		pieces[0] = (piece_index % self.game.template.width != 0) ? board[piece_index - 1] : "X"
		# Right
		pieces[1] = (piece_index % self.game.template.width != self.game.template.width - 1) ? board[piece_index + 1] : "X"
		# Top
		pieces[2] = (piece_index >= self.game.template.width) ? board[piece_index - self.game.template.width] : "X"
		# Bottom
		pieces[3] = (piece_index / self.game.template.width < self.game.template.height - 1) ? board[piece_index + self.game.template.width] : "X"

		return pieces
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

	def has_adjacent_at_least(piece_index, types, count)
		c = 0
		f = Hash.new

		pieces = get_adjacent_pieces(piece_index)

		[0,1,2,3].each do |i|
			if pieces[i] && types.include?(pieces[i].to_sym) && !f.has_key?(pieces[i])
				c += 1 
				f[pieces[i]] = true
			end
		end
		return true if c >= count
	end

	# -----------------------------------------------------------------
	# Places a piece on the board for this turn only.
	#
	# Returns "CREATE_COMPANY" if this piece placement would result in the start
	# 	of a company.
	# Returns "MERGE_STARTED" if a merge will be triggered by this piece placement.
	# Returns "PIECE_PLACED" if no further action will be triggered.
	# -----------------------------------------------------------------
	def test_place_piece (row, column)
		piece_index = self.piece_index(row, column)

		adjacent_companies = test_merge(row, column)

		# If we are connected to company, this tile will merge into that company
		# and this is considered just a standard piece placement.
		return PIECE_PLACED if adjacent_companies.size == 1

		# If we are placing a piece that is connected to more than one company,
		# then by definition this is a merger, and we need to trigger the merge
		# process
		return MERGE_STARTED if adjacent_companies.size >= 2

		# If we are connected to no companies, but we are connected to an unspecifed
		# piece on the board and there are still companies that can be established,
		# then we can trigger the start of a company.
	 	return COMPANY_STARTED if has_adjacent(piece_index, Set.new([:u])) && can_start_company

	 	# By default, piece placement doesn't "do" anything if it is a loan piece.
	 	return PIECE_PLACED
	end

	# -----------------------------------------------------------------
	# Returns a hash of the companies that would be merged if a piece
	# was placed at row, column
	# -----------------------------------------------------------------
	def test_merge(row, column)
		piece_index = self.piece_index(row, column)

		# Is this piece connected to other companies that are already started?
		adjacent_companies = {}
		companies = data_hash["companies"]
		companies.each do |key, company|
			adjacent_companies[company["abbr"]] = company if has_adjacent(piece_index, Set.new([company["abbr"].to_sym]))
		end
		return adjacent_companies
	end

	# -----------------------------------------------------------------
	# Places a piece on the board for this turn only. This should ONLY
	# be called when the piece placement has been tested to either:
	#     1) Create a new company
	#     2) Add to a current company
	#     3) Not do anything
	# During merging, call place_piece_merge_companies_into which requires
	# that you pass which company will be retained.
	# -----------------------------------------------------------------
	def place_piece (row, column)
		new_board = self.board.dup
		piece_index = self.piece_index(row, column);		

		# Is this piece connected to another company that is already started?
		companies = data_hash["companies"]
		companies.each do |key, company|
			if has_adjacent(piece_index, Set.new([company["abbr"].to_sym]))
				new_board[piece_index] = company["abbr"]

				# Okay, we have to find all the OTHER pieces that this
				# might have connected to as well, and update those.
				tiles = get_connected_tiles(row, column)

				tiles.each do |key,value|
					new_board[value["index"]] = company["abbr"]
				end

				# save the board again.
				self.update_attributes(:board => new_board)
				return
			end
		end

		# Is this a piece not connected to any other already placed pieces?
		new_board[piece_index] = "u"
		self.update_attributes(:board => new_board)
	end

	# -----------------------------------------------------------------
	# Places a piece on the board that will cause a merger. The company
	# passed in will be the company retained, so all other tiles will switch
	# to this new company.
	# -----------------------------------------------------------------
	def place_piece_merge_companies_into (row, column, company_abbr)
		new_board = self.board.dup
		piece_index = self.piece_index(row, column);		

		# Replace the merge marker ("+") with our company marker
		new_board[piece_index] = company_abbr

		# Okay, we have to find all the OTHER pieces that this
		# might did connect to, and update those.
		tiles = get_connected_tiles(row, column)

		tiles.each do |key,value|
			new_board[value["index"]] = company_abbr
		end

		# save the board again.
		self.update_attributes(:board => new_board)
	end

	# -----------------------------------------------------------------
	# Returns all the cells connected to row,column that are not "e" cells
	# -----------------------------------------------------------------
	def get_connected_tiles(row, column)
	    get_connected_tiles_recurse(row, column, {});
	end

	def get_connected_tiles_recurse(row, column, map)
	    left = column > 0 ? get_tile_at(row, column - 1) : nil;
	    right = column < game.template.width - 1 ? get_tile_at(row, column + 1) : nil;
	    top = row > 0 ? get_tile_at(row - 1, column) : nil;
	    bottom = row < game.template.height - 1 ? get_tile_at(row + 1, column) : nil;

	    [left, right, top, bottom].each do |item|
	        if item && item["row"] && item["column"] && item["tile"] != "e" && item["tile"] != "!" && !item["tile"].is_int? && !map.has_key?(item["key"])
	            map[item["key"]] = item;
	            get_connected_tiles_recurse(item["row"], item["column"], map);
	        end
	    end
	    return map
	end

	# -----------------------------------------------------------------
	# Starts a company of all cells connected to the provided row, column
	# -----------------------------------------------------------------
	def start_company_at(row, column, company_abbr)
		tiles = get_connected_tiles(row, column)

		new_board = board.dup

		tiles.each do |key, value|
			new_board[value["index"]] = company_abbr	
		end

		update_attributes(:board => new_board)

		return tiles.size
	end

	# -----------------------------------------------------------------
	# Returns the number of established companies (companies with size > 0)
	# -----------------------------------------------------------------
	def num_established_companies
		num = 0
		companies = data_hash["companies"]
		companies.each do |key, company|
			num = num + 1 if company["size"] > 0
		end
		return num
	end

	# -----------------------------------------------------------------
	# Returns true if a company can be started
	# -----------------------------------------------------------------
	def can_start_company()
		return num_established_companies() < companies = data_hash["companies"].size
	end

	# -----------------------------------------------------------------
	# Returns true if the player can purchase stock
	# -----------------------------------------------------------------
	def can_purchase_stock(player)
		return num_established_companies() > 0
	end

	# -----------------------------------------------------------------
	# Returns true if the player has stock in the company provided
	# -----------------------------------------------------------------
	def player_has_stock_in(player_index, company_abbr)
		val = data_hash["players"][player_index]["stock_count"][company_abbr]
		return false if val == nil || val == 0
		return true
	end

	# -----------------------------------------------------------------
	# Marks the board with a merge marker during the merge process.
	# -----------------------------------------------------------------
	def mark_merge_at(row, column)
		piece_index = self.piece_index(row, column);		
		new_board = board.dup
		new_board[piece_index] = "+"
		update_attributes(:board => new_board)
	end

	# -----------------------------------------------------------------
	# Returns true if the provided player has enough money to purchase
	# any stock.
	# -----------------------------------------------------------------
	def player_can_purchase_any_stock(player_index)
		cheapest_stock = 100000

		# Loop through all the companies and find the cheapest stock option
		companies = data_hash["companies"]
		companies.each do |key, company|
			if company["size"] > 0
				value = stock_value_for(key)

				cheapest_stock = value if value < cheapest_stock
			end
		end

		return data_hash["players"][player_index]["money"] >= cheapest_stock
	end

	# -----------------------------------------------------------------
	# Marks all squares that cannot have a tile placed
	# -----------------------------------------------------------------
	def mark_impossible_tiles()
		new_board = board.dup
		large_companies = Set.new

		# First we find all the companies that are larger than a set size
		companies = data_hash["companies"]
		companies.each do |key, company|
			large_companies.add(key.to_sym) if company["size"] >= 11
		end

		for i in 0..board.size
			if has_adjacent_at_least(i, large_companies, 2)
				# We have to replace any player tiles we might be overwriting
				if new_board[i].is_int?
					player_index = new_board[i]
					new_board[i] = "!" 
					unused_index = get_random_unused_tile
					new_board[unused_index] = player_index
				else
					new_board[i] = "!" 
				end
			end
		end

		update_attributes(:board => new_board)
	end

	def get_tile_name(row, column)
		return (65 + row.to_i).chr.to_s + "-" + (column + 1).to_s
	end
end
