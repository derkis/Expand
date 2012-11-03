module Engine

	def self.run_action(game, action, controller)
		game.cur_turn.update_attributes(:action => ActiveSupport::JSON.encode(action))

		data_hash = game.cur_turn.data_hash
		case data_hash['state']
			#--------------------------------------
			# PIECE PLACEMENT
			#--------------------------------------
			when Turn::PLACE_PIECE
				place_piece_result = game.cur_turn.place_piece(action["row"], action["column"])

				game.cur_turn.refresh_player_tiles
				game.cur_turn.save!

				case place_piece_result
					when Turn::PIECE_PLACED
						if game.cur_turn.can_purchase_stock(game.cur_turn.player)
							game.advance_turn
						else
							game.advance_turn_step
							data_hash['state'] = Turn::PURCHASE_STOCK
							game.cur_turn.serialize_data_hash(data_hash)
						end
					when Turn::COMPANY_STARTED
						data_hash['state'] = Turn::START_COMPANY
						game.cur_turn.serialize_data_hash(data_hash)
					when Turn::MERGE_STARTED

				end

			#--------------------------------------
			# START_COMPANY
			#--------------------------------------
			when Turn::START_COMPANY
				size = game.cur_turn.start_company_at(action["row"], action["column"], action["company_abbr"])
				data_hash['state'] = Turn::PURCHASE_STOCK
				data_hash["companies"][action["company_abbr"]]["size"] = size
				game.cur_turn.serialize_data_hash(data_hash)

			#--------------------------------------
			# PURCHASE_STOCK
			#--------------------------------------
			when Turn::PURCHASE_STOCK
				action["stocks_purchased"].each do |key, value|
					data_hash["companies"][key]["stock_count"] = data_hash["companies"][key]["stock_count"] - value
					if data_hash["players"][game.cur_turn.player.index]["stock_count"].has_key?(key)
						data_hash["players"][game.cur_turn.player.index]["stock_count"][key] = data_hash["players"][game.cur_turn.player.index]["stock_count"][key] + value
					else
						data_hash["players"][game.cur_turn.player.index]["stock_count"][key] = value
					end
					game.advance_turn
				end
		end
	end
end