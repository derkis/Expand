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
		end

		game.cur_turn.refresh_company_sizes
		game.cur_turn.update_attributes(:action => ActiveSupport::JSON.encode(action))
	end
end