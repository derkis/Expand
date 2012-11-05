module Engine
	def self.previous_turn(game)
		# First we delete the current turn, then we revert to the previous one.
		prev_number = game.cur_turn.number - 1

		return if prev_number < 0

		game.cur_turn = Turn.where("number = ? AND game_id = ?", prev_number, game.id).first
	end

	def self.next_turn(game)
		# First we delete the current turn, then we revert to the previous one.
		next_turn = Turn.where("number = ? AND game_id = ?", game.cur_turn.number + 1, game.id).first

		if next_turn
			game.cur_turn = next_turn
		end
	end

	def self.run_action(game, action, controller)
		if action.has_key?("previous_turn")
			return Engine.previous_turn(game)
		end

		if action.has_key?("next_turn")
			return Engine.next_turn(game)
		end

		case game.cur_turn.data_hash['state']
			#--------------------------------------
			# PIECE PLACEMENT
			#--------------------------------------
			when Turn::PLACE_PIECE
				place_piece_result = game.cur_turn.test_place_piece(action["row"], action["column"])

				case place_piece_result
					when Turn::PIECE_PLACED
						# Switch to stock purchasing (if can purchase stock) or advanced the turn
						if !game.cur_turn.can_purchase_stock(game.cur_turn.player)
							game.advance_turn
							game.cur_turn.place_piece(action["row"], action["column"])
							game.cur_turn.refresh_player_tiles
						else
							game.advance_turn_step
							game.cur_turn.place_piece(action["row"], action["column"])
							data_hash = game.cur_turn.data_hash
							data_hash['state'] = Turn::PURCHASE_STOCK
							game.cur_turn.serialize_data_hash(data_hash)
							# We refresh player tiles AFTER they have purchased their stock!
						end
					when Turn::COMPANY_STARTED
						game.advance_turn_step
						game.cur_turn.place_piece(action["row"], action["column"])
						data_hash = game.cur_turn.data_hash
						data_hash['state'] = Turn::START_COMPANY
						game.cur_turn.serialize_data_hash(data_hash)
						# We refresh player tiles AFTER they have purchased their stock!
					when Turn::MERGE_STARTED
						game.advance_turn_step
						data_hash = game.cur_turn.data_hash
						data_hash['state'] = Turn::MERGE_CHOOSE_COMPANY
						data_hash['merge_state'] = {
													"row"=>action["row"],
													"column"=>action["column"],
													"companies_to_merge"=>{}
													}
						companies_merged = game.cur_turn.test_merge(action["row"], action["column"])

						companies_merged.each do |key, company|
							data_hash['merge_state']["companies_to_merge"][key] = true
						end

						game.cur_turn.serialize_data_hash(data_hash)
				end

			#--------------------------------------
			# START_COMPANY
			#--------------------------------------
			when Turn::START_COMPANY
				game.advance_turn_step
				game.cur_turn.start_company_at(action["row"], action["column"], action["company_abbr"])
				data_hash = game.cur_turn.data_hash
				data_hash['state'] = Turn::PURCHASE_STOCK
				data_hash["companies"][action["company_abbr"]]["stock_count"] -= 1

				# Update stock value on the player by 1
				if data_hash["players"][game.cur_turn.player.index]["stock_count"].has_key?(action["company_abbr"])
					data_hash["players"][game.cur_turn.player.index]["stock_count"][action["company_abbr"]] += 1
				else
					data_hash["players"][game.cur_turn.player.index]["stock_count"][action["company_abbr"]] = 1
				end

				game.cur_turn.serialize_data_hash(data_hash)

			#--------------------------------------
			# PURCHASE_STOCK
			#--------------------------------------
			when Turn::PURCHASE_STOCK
				game.advance_turn_step

				data_hash = game.cur_turn.data_hash

				cost = 0

				action["stocks_purchased"].each do |key, value|

					# Update stock value on the company
					data_hash["companies"][key]["stock_count"] -= value

					# Update stock value on the player
					if data_hash["players"][game.cur_turn.player.index]["stock_count"].has_key?(key)
						data_hash["players"][game.cur_turn.player.index]["stock_count"][key] += + value
					else
						data_hash["players"][game.cur_turn.player.index]["stock_count"][key] = value
					end

					# Keep track of total cost
					cost = cost + (game.cur_turn.stock_value_for(key) * value)
				end

				# Subtract cost from player money
				data_hash["players"][game.cur_turn.player.index]["money"] -= cost
				game.cur_turn.serialize_data_hash(data_hash)

				# Give the player their extra tile
				game.cur_turn.refresh_player_tiles

				game.advance_turn
			#--------------------------------------
			# MERGE_CHOOSE_COMPANY
			#--------------------------------------
			when Turn::MERGE_CHOOSE_COMPANY
				data_hash = game.cur_turn.data_hash

				# Here the client will have sent us the company abbreviation to retain
				company_abbr = action["company_abbr"]
				row = data_hash["merge_state"]["row"]
				column = data_hash["merge_state"]["column"]

				# Now we place the piece, telling the turn which company is being
				# retained
				game.cur_turn.place_piece_merge_companies_into(row, column, company_abbr)
				
				data_hash['state'] = Turn::MERGE_CHOOSE_STOCK_OPTIONS
				data_hash['merge_state']["company_abbr"] = company_abbr

				# Create a collection of companies that still need stock options chosen for
				data_hash['merge_state']["company_options_left"] = data_hash['merge_state']["companies_to_merge"].dup
				# Remove the company that is the retained company
				data_hash['merge_state']["company_options_left"].delete(company_abbr)
				# Pick the first company that needs to have stock options chosen for it
				data_hash['merge_state']["cur_company_options"] = data_hash['merge_state']["company_options_left"].to_a()[0][0]
				data_hash['merge_state']["company_options_left"].delete(data_hash['merge_state']["cur_company_options"])

				# Setup the first player to be making a decision
				data_hash['merge_state']["stock_option_player_index"] = game.cur_turn.player.index

				game.cur_turn.serialize_data_hash(data_hash)
			#--------------------------------------
			# MERGE_CHOOSE_STOCK_OPTIONS
			#--------------------------------------
			when Turn::MERGE_CHOOSE_STOCK_OPTIONS
				binding.pry
				data_hash = game.cur_turn.data_hash
				player_index = data_hash['merge_state']["stock_option_player_index"]
				next_player_index = (player_index+1) % game.players.count

				# We continue on this cycle until we wrap around to the player who
				# initiated this debacle of merging madness at which point we should
				# technically move on to the next company in the sequence until there
				# are no companies next
				if next_player_index == game.cur_player_index
					data_hash.delete("merge_state")
					data_hash['state'] = Turn::PURCHASE_STOCK
				else
					company_from = data_hash['merge_state']["cur_company_options"]
					company_to = data_hash['merge_state']["company_abbr"]

					# The client will have sent us the options:
					#   sell: the number of stocks to sell
					#   split: the number of stocks to split 2-for-1 into the new company (should
					#	be a multiple of 2)
					
					# Deal with split stock first.
					split = action["stock_split"]
					data_hash["players"][player_index]["stock_count"][company_from] -= split
					if data_hash["players"][player_index]["stock_count"].has_key?(company_to)
						data_hash["players"][player_index]["stock_count"][company_to] += (split / 2)
					else
						data_hash["players"][player_index]["stock_count"][company_to] = (split / 2)
					end

					# Deal with sold stock next.
					sold = action["stock_sold"]
					data_hash["players"][player_index]["money"] += (sold * game.cur_turn.stock_value_for(company_from))
					if data_hash["players"][player_index]["stock_count"].has_key?(company_from)
						data_hash["players"][player_index]["stock_count"][company_from] -= sold
					end

					data_hash['merge_state']["stock_option_player_index"] = next_player_index
				end
				
				game.cur_turn.serialize_data_hash(data_hash)
		end

		game.cur_turn.refresh_company_sizes
		game.cur_turn.update_attributes(:action => ActiveSupport::JSON.encode(action))
	end
end