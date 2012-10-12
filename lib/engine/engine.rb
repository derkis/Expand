module Engine

	def self.interpret_turn(game, turn_update, controller)
		# 1) Update current turns action data
		turn_action = turn_update['action']
		game.current_turn.action = turn_action
		game.current_turn.save!

		operation = Engine.operation_for_turn_type(turn_action['turn_type'].intern)

		# 3) Run the operation and Shift game to new turn, if the operation returns true
		game.advance_turn if operation.call(game.current_turn, turn_action, controller)
	end

	def self.operation_for_turn_type(key)
		case key
		
		when :reset
			return lambda do |current_turn, turn_action, controller|
				controller.redirect_to "/games/test"
				true # Let the controller know we are doing a redirect
			end

		when :no_action
			return lambda do |current_turn, turn_action, controller|
				raise 'Engine attempted to parse a no_action turn'
			end
		
		when :place_piece
			return lambda do |current_turn, turn_action, controller|
				row, column = turn_action['row'], turn_action['column']
				ret = current_turn.place_piece_for(row, column, current_turn.player)

				if ret == "CREATE_COMPANY"
					current_turn.update_attributes(:action => ActiveSupport::JSON.encode(
						{:place => {:row => row, :column => column},
						 :start_company => true}))
					ret = false
				else
					current_turn.action = ActiveSupport::JSON.encode({:place => {:row => row, :column => column}, :start_company => false})
					ret = true
				end

				current_turn.refresh_player_tiles
				current_turn.save
				ret
			end 
		
		when :start_company
			return lambda do |current_turn, turn_action, controller|
				raise 'start_company not implemented'
			end

		when :purchase_stock
			return lambda do |current_turn, turn_action, controller|
				raise 'purchase_stock not implemented'
			end

		when :trade_stock
			return lambda do |current_turn, turn_action, controller|
				raise 'trade_stock not implemented'
			end

		when :merge_order
			return lambda do |current_turn, turn_action, controller|
				raise 'merge_order not implemented'
			end
		end
	end
end