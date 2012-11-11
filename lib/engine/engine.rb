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

	def self.forfeit(game, current_user)
		data_hash = game.cur_turn.data_hash
		data_hash["forfeited_by"] = current_user.email

		game.cur_turn.serialize_data_hash(data_hash)

		game.finish
	end

	def self.run_action(game, action, controller)
		# Ensure that only the current player can actually perform an action
		if (controller.current_user.id != game.cur_turn.player.user.id &&
			game.cur_turn.data_hash["state"] != Turn::MERGE_CHOOSE_STOCK_OPTIONS) &&
			!game.debug_mode
			return
		end

		if action.has_key?("previous_turn")
			return Engine.previous_turn(game)
		end

		if action.has_key?("next_turn") && game.debug_mode
			return Engine.next_turn(game)
		end

		if action.has_key?("forfeit")
			return Engine.forfeit(game, controller.current_user)
		end

		# If the person making the action is the current player for this turn and
		# they have specified they want to end the game, then we update a flag on the turn
		# data that indicates the game is ending. Then when advance_turn is called, it will
		# check if that flag is true and if it is it will end the game.
		if (action.has_key?("end_game") && action["end_game"] == true && game.can_end_game && 
			controller.current_user.id == game.cur_turn.player.user.id || game.debug_mode)

			data_hash = game.cur_turn.data_hash
			data_hash["ending_game"] = true
			game.cur_turn.serialize_data_hash(data_hash)
		end

		case game.cur_turn.data_hash['state']
			#--------------------------------------
			# PIECE PLACEMENT
			#--------------------------------------
			when Turn::PLACE_PIECE
				place_piece_result = game.cur_turn.test_place_piece(action["row"], action["column"])
				tile_name = game.cur_turn.get_tile_name(action["row"], action["column"])

				case place_piece_result

					when Turn::PIECE_PLACED
						# Switch to stock purchasing (if can purchase stock) or advanced the turn
						if !game.cur_turn.can_purchase_stock(game.cur_turn.player)
							Engine.add_notification(game, nil, game.cur_turn.player.user.email + " placed " + tile_name + ".", true)

							game.advance_turn
							game.cur_turn.place_piece(action["row"], action["column"])

							game.cur_turn.refresh_player_tiles
						else
							game.advance_turn_step
							
							Engine.add_notification(game, nil, game.cur_turn.player.user.email + " placed " + tile_name + ".", true)

							game.cur_turn.place_piece(action["row"], action["column"])

							Engine.goto_purchase_stock_or_advance_turn(game, game.cur_turn.data_hash)
						end
					when Turn::COMPANY_STARTED
						game.advance_turn_step
						game.cur_turn.place_piece(action["row"], action["column"])
						data_hash = game.cur_turn.data_hash
						data_hash['state'] = Turn::START_COMPANY
						Engine.add_notification(game, data_hash, game.cur_turn.player.user.email + " placed " + tile_name + ".", false)
						game.cur_turn.serialize_data_hash(data_hash)
						# We refresh player tiles AFTER they have purchased their stock!
					when Turn::MERGE_STARTED
						game.advance_turn_step
						data_hash = game.cur_turn.data_hash

						data_hash['merge_state'] = {
													"row"=>action["row"],
													"column"=>action["column"],
													"companies_to_merge"=>{}
													}

						companies_merged = game.cur_turn.test_merge(action["row"], action["column"])

						game.cur_turn.mark_merge_at(action["row"], action["column"])

						largest_company_size = 0
						largest_company_abbr = ""
						last_company_size = -1
						all_same_size = true

						companies_being_acquired_txt = ""

						companies_merged.each do |key, company|
							if company["size"] > largest_company_size
								largest_company_size = company["size"] 
								largest_company_abbr = company["abbr"]
							end
							all_same_size = false if last_company_size != -1 && last_company_size != company["size"]
							data_hash['merge_state']["companies_to_merge"][key] = true

							last_company_size = company["size"]
						end

						if all_same_size
							# Okay, we only want to give a merge option if the companies involved
							# in the merge are the SAME SIZE
							data_hash['state'] = Turn::MERGE_CHOOSE_COMPANY
						else
							data_hash['state'] = Turn::MERGE_CHOOSE_STOCK_OPTIONS
							data_hash['merge_state']["company_abbr"] = largest_company_abbr

							# Create a collection of companies that still need stock options chosen for
							data_hash['merge_state']["company_options_left"] = data_hash['merge_state']["companies_to_merge"].dup
							# Remove the company that is the retained company
							data_hash['merge_state']["company_options_left"].delete(largest_company_abbr)

							data_hash['merge_state']["company_options_left"].each do |c_a, company|
								companies_being_acquired_txt += " and " if companies_being_acquired_txt.length > 0
								companies_being_acquired_txt += Engine.company_html(data_hash["companies"][c_a])
							end
							
							# Pick the first company that needs to have stock options chosen for it
							data_hash['merge_state']["cur_company_options"] = data_hash['merge_state']["company_options_left"].to_a()[0][0]
							data_hash['merge_state']["company_options_left"].delete(data_hash['merge_state']["cur_company_options"])

							# Setup the first player to be making a decision
							data_hash['merge_state']["stock_option_player_index"] = Engine.find_first_player_index_with_stock_in(game, data_hash['merge_state']["cur_company_options"])

							# First we award majority and minority to every single company that has been dissolved
							# (obviously we need to exclude the company that remains)
							data_hash["merge_state"]["companies_to_merge"].each do |c_a, company|
								Engine.award_majority_minority(game, data_hash, c_a) if c_a != largest_company_abbr
							end

							Engine.add_notification(game, data_hash, game.cur_turn.player.user.email \
													+ " caused " \
													+ Engine.company_html(data_hash["companies"][largest_company_abbr]) \
													+ " to acquire " \
													+ companies_being_acquired_txt \
													+ " at " \
													+ tile_name \
													+ ".", false)
						end

						game.cur_turn.serialize_data_hash(data_hash)
				end

			#--------------------------------------
			# START_COMPANY
			#--------------------------------------
			when Turn::START_COMPANY
				if action["company_abbr"] == ""
					return
				end

				game.cur_turn.start_company_at(action["row"], action["column"], action["company_abbr"])
				data_hash = game.cur_turn.data_hash

				data_hash["companies"][action["company_abbr"]]["stock_count"] -= 1

				# Update stock value on the player by 1
				if data_hash["players"][game.cur_turn.player.index]["stock_count"].has_key?(action["company_abbr"])
					data_hash["players"][game.cur_turn.player.index]["stock_count"][action["company_abbr"]] += 1
				else
					data_hash["players"][game.cur_turn.player.index]["stock_count"][action["company_abbr"]] = 1
				end

				Engine.add_notification(game, data_hash, game.cur_turn.player.user.email + " started " + Engine.company_html(data_hash["companies"][action["company_abbr"]]), false)
				Engine.goto_purchase_stock_or_advance_turn(game, data_hash)

			#--------------------------------------
			# PURCHASE_STOCK
			#--------------------------------------
			when Turn::PURCHASE_STOCK
				game.advance_turn_step

				data_hash = game.cur_turn.data_hash

				cost = 0

				purchase_text = ""

				action["stocks_purchased"].each do |key, value|

					# Update stock value on the company
					data_hash["companies"][key]["stock_count"] -= value

					# Update stock value on the player
					if data_hash["players"][game.cur_turn.player.index]["stock_count"].has_key?(key)
						data_hash["players"][game.cur_turn.player.index]["stock_count"][key] += value
					else
						data_hash["players"][game.cur_turn.player.index]["stock_count"][key] = value
					end

					# Keep track of total cost
					cost = cost + (game.cur_turn.stock_value_for(key) * value)

					purchase_text += ", " if purchase_text.length > 0
					purchase_text += value.to_s + " " + Engine.company_html(data_hash["companies"][key])
				end

				# Subtract cost from player money
				data_hash["players"][game.cur_turn.player.index]["money"] -= cost

				purchase_text = "nothing" if purchase_text.length == 0

				Engine.add_notification(game, data_hash, game.cur_turn.player.user.email + " purchased " + purchase_text, false)

				game.cur_turn.serialize_data_hash(data_hash)

				# Give the player their extra tile
				game.cur_turn.refresh_player_tiles

				game.advance_turn
			#--------------------------------------
			# MERGE_CHOOSE_COMPANY
			#--------------------------------------
			when Turn::MERGE_CHOOSE_COMPANY
				game.advance_turn_step

				data_hash = game.cur_turn.data_hash

				# Here the client will have sent us the company abbreviation to retain
				company_abbr = action["company_abbr"]
				row = data_hash["merge_state"]["row"]
				column = data_hash["merge_state"]["column"]
				
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
				data_hash['merge_state']["stock_option_player_index"] = Engine.find_first_player_index_with_stock_in(game, data_hash['merge_state']["cur_company_options"])

				# First we award majority and minority to every single company that has been dissolved
				# (obviously we need to exclude the company that remains)
				companies_text = ""

				data_hash["merge_state"]["companies_to_merge"].each do |c_a, company|
					if c_a != company_abbr
						companies_text += ", " if companies_text.length > 0
						companies_text += Engine.company_html(data_hash["companies"][c_a])
						Engine.award_majority_minority(game, data_hash, c_a) if c_a != company_abbr
					end
				end

				Engine.add_notification(game, data_hash, Engine.company_html(data_hash["companies"][company_abbr]) + " is acquiring " + companies_text, false)

				game.cur_turn.serialize_data_hash(data_hash)
			#--------------------------------------
			# MERGE_CHOOSE_STOCK_OPTIONS
			#--------------------------------------
			when Turn::MERGE_CHOOSE_STOCK_OPTIONS
				data_hash = game.cur_turn.data_hash

				company_from = data_hash['merge_state']["cur_company_options"]
				company_to = data_hash['merge_state']["company_abbr"]

				player_index = data_hash['merge_state']["stock_option_player_index"]

				text = ""

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

				data_hash["companies"][company_from]["stock_count"] += split
				data_hash["companies"][company_to]["stock_count"] -= (split / 2)

				# Deal with sold stock next.
				sold = action["stock_sold"]
				data_hash["players"][player_index]["money"] += (sold * game.cur_turn.stock_value_for(company_from))
				if data_hash["players"][player_index]["stock_count"].has_key?(company_from)
					data_hash["players"][player_index]["stock_count"][company_from] -= sold
				end

				data_hash["companies"][company_from]["stock_count"] += sold

				Engine.add_notification(game, data_hash, game.player_by_index(player_index).user.email + " split " + split.to_s + " and sold " + sold.to_s + " stock in " + Engine.company_html(data_hash["companies"][company_from]), false)

				# We continue on this cycle until we wrap around to the player who
				# initiated this debacle of merging madness.
				next_player_index = (player_index+1) % game.players.count 

				return Engine.finalize_merge(game, data_hash) if next_player_index == game.cur_player_index

				while !game.cur_turn.player_has_stock_in(next_player_index, company_from)
					next_player_index = (next_player_index+1) % game.players.count

					return Engine.finalize_merge(game, data_hash) if next_player_index == game.cur_player_index
				end

				data_hash['merge_state']["stock_option_player_index"] = next_player_index

				game.cur_turn.serialize_data_hash(data_hash)
		end

		game.cur_turn.mark_impossible_tiles
		game.cur_turn.refresh_company_sizes

		game.cur_turn.update_attributes(:action => ActiveSupport::JSON.encode(action))
	end

	def self.award_majority_minority(game, data_hash, company_abbr)
		stock_counts = []

		majority_money = game.cur_turn.stock_value_for(company_abbr, "bonus_maj")
		minority_money = game.cur_turn.stock_value_for(company_abbr, "bonus_min")

		notification = ""

		# First find the stock counts in the company
		data_hash["players"].each_with_index do |player, i|
			stock_counts.push(player["stock_count"][company_abbr]) if player["stock_count"][company_abbr] != 0 && player["stock_count"][company_abbr] != nil
		end

		# Eliminate duplicates
		stock_counts = stock_counts & stock_counts

		# Sort in descending order
		stock_counts = stock_counts.sort.reverse!

		# If there is only one value the majority and minority are shared by everyone involved
		if stock_counts.size == 1
			majority_minority = stock_counts[0]
			winnarz = []
			data_hash["players"].each_with_index do |player, i|
				winnarz.push(player) if player["stock_count"][company_abbr] == majority_minority
			end

			award = (majority_money + minority_money) / winnarz.size

			notification = ""

			winnarz.each_with_index do |player, i|
				notification += ", " if notification.length > 0
				notification += game.player_by_index(player["index"]).user.email
				player["money"] += award
			end

			notification += (winnarz.size == 1 ? " is " : " are ") \
							+ " awarded majority + minority of $" \
							+ award.to_s \
							+ " for having " \
							+ stock_counts[0].to_s \
							+ " stock in " \
							+ Engine.company_html(data_hash["companies"][company_abbr]) \
							+ "."

			Engine.add_notification(game, data_hash, notification, false)
		else
			# Now find the count of players for majority and minority
			majority = stock_counts[0]
			minority = stock_counts[1]

			majority_winnarz = []
			minority_winnarz = []

			data_hash["players"].each_with_index do |player, i|
				majority_winnarz.push(player) if player["stock_count"][company_abbr] == majority
				minority_winnarz.push(player) if player["stock_count"][company_abbr] == minority
			end

			if majority_winnarz.size == 1
				award = majority_money / majority_winnarz.size

				Engine.add_notification(game, data_hash, "Majority of $" + award.to_s + " awarded to " + game.player_by_index(majority_winnarz[0]["index"]).user.email + " for having " + stock_counts[0].to_s + " stock.", false)
				majority_winnarz[0]["money"] += award

				award = minority_money / majority_winnarz.size

				minority_winnarz.each_with_index do |player, i|
					Engine.add_notification(game, data_hash, "Minority of $" + award.to_s + " awarded to " + game.player_by_index(player["index"]).user.email  + " for having " + stock_counts[1].to_s + " stock.", false)
					player["money"] += minority_money / minority_winnarz.size
				end
			else
				award = (majority_money + minority_money) / majority_winnarz.size

				majority_winnarz.each_with_index do |player, i|
					Engine.add_notification(game, data_hash, "Majority/Minority split of $" + award.to_s + " awarded to " + game.player_by_index(player["index"]).user.email  + " for having " + stock_counts[0].to_s + " stock each.", false)
					player["money"] += award
				end
			end
		end
	end

	def self.goto_purchase_stock_or_advance_turn(game, data_hash)
		game.cur_turn.refresh_company_sizes

		# We want to see if the player in question has enough resources to buy
		# any stock. If they do not, we just advance the turn. If they do
		# we go into purchase stock phase.
		if game.cur_turn.player_can_purchase_any_stock(game.cur_player_index)
			game.advance_turn_step
			data_hash['state'] = Turn::PURCHASE_STOCK
			# We refresh player tiles AFTER they have purchased their stock!
		else
			game.advance_turn
			game.cur_turn.refresh_player_tiles
			data_hash['state'] = Turn::PLACE_PIECE
		end

		game.cur_turn.serialize_data_hash(data_hash)
	end

	# Finds the next player with stock in the company provided.
	def self.find_first_player_index_with_stock_in(game, company_abbr)
		next_player_index = game.cur_player_index

		while !game.cur_turn.player_has_stock_in(next_player_index, company_abbr)
			next_player_index = (next_player_index+1) % game.players.count
		end

		return next_player_index
	end

	def self.finalize_merge(game, data_hash)
		row = data_hash["merge_state"]["row"]
		column = data_hash["merge_state"]["column"]
		company_abbr = data_hash["merge_state"]["company_abbr"]

		# Delete the merge_state from the hash
		data_hash.delete("merge_state")

		# Update the board and flip all the tiles to the remaining company
		game.cur_turn.place_piece_merge_companies_into(row, column, company_abbr)

		# Advance the turn or goto purchasing stocks for the current player
		Engine.goto_purchase_stock_or_advance_turn(game, data_hash)

		game.cur_turn.refresh_company_sizes
	end

	def self.add_notification(game, data_hash, message, save_immediately)
		data_hash = game.cur_turn.data_hash if !data_hash

		data_hash["notifications"] = [] if !data_hash.has_key?("notifications")

		# We only retain notifications for the last 2 turns
		while (data_hash["notifications"].size > 0 && (data_hash["notifications"][0]["turn_number"] < game.cur_turn.number - 2 || data_hash["notifications"][0]["turn_number"] > game.cur_turn.number))
			data_hash["notifications"].shift
		end 

		data_hash["notifications"].push({
											"message" => message,
											"turn_number" => game.cur_turn.number + 1,
											"turn_step" => game.cur_turn.step
										})

		game.cur_turn.serialize_data_hash(data_hash) if save_immediately
	end

	def self.company_html(company)
		return "<span style='color: " + company["color"] + ";'>" + company["name"] + "</span>"
	end
end