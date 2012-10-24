module Engine

	def self.run_action(game, action, controller)
		game.cur_turn.update_attributes(:action => ActiveSupport::JSON.encode(action))

		case game.cur_turn.data_object["state"]
			#--------------------------------------
			# PIECE PLACEMENT
			#--------------------------------------
			when Turn::State::PLACE_PIECE
				place_piece_result = game.cur_turn.place_piece(action["row"], action["column"])
				
				game.cur_turn.refresh_player_tiles
				game.cur_turn.save!

				game.advance_turn if place_piece_result == Turn::Result::COMPANY_STARTED
			
			#--------------------------------------
			# START_COMPANY
			#--------------------------------------
			when Turn::State::START_COMPANY
				raise 'start_company not implemented'
		end
	end
end