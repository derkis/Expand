module Engine

	def self.run_action(game, action, controller)
		game.cur_turn.action = action

		case cur_turn.data_object["state"]
			#--------------------------------------
			# PIECE PLACEMENT
			#--------------------------------------
			when Turn.STATE_PLACE_PIECE
					place_piece_result = cur_turn.place_piece(action["row"], action["column"], cur_turn.player)
					
					game.cur_turn.refresh_player_tiles
					game.cur_turn.save!

					game.advance_turn if place_piece_result == Turn.PIECE_PLACED_COMPANY_STARTED
			
			#--------------------------------------
			# START_COMPANY
			#--------------------------------------
			when Turn.STATE_START_COMPANY
					raise 'start_company not implemented'
		end
	end
end