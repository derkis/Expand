module Engine

	def self.interpret_turn(game, turn_update)
		# 1) Update current turns action data
		turn_action = turn_update['action']
		game.current_turn.action = turn_action
		game.current_turn.save!

		# 2) Shift game to new turn, which will update current_turn to the new one
		game.next_turn

		# 3) Now modify the current_turn
		operation = Engine.operation_for_turn_type(turn_action['turn_type'].intern)
		operation.call(game.current_turn, turn_action)
	end

	def self.operation_for_turn_type(key)
		case key
		
		when :no_action
			return lambda do |current_turn, turn_action|
				raise 'Engine attempted to parse a no_action turn'
			end
		
		when :place_piece
			return lambda do |current_turn, turn_action|
				row, column = turn_action['row'], turn_action['column']
				current_turn.place_piece_for(row, column, current_turn.player)
			end 
		
		when :start_company
			return lambda do |current_turn, turn_action|
				raise 'start_company not implemented'
			end

		when :purchase_stock
			return lambda do |current_turn, turn_action|
				raise 'purchase_stock not implemented'
			end

		when :trade_stock
			return lambda do |current_turn, turn_action|
				raise 'trade_stock not implemented'
			end

		when :merge_order
			return lambda do |current_turn, turn_action|
				raise 'merge_order not implemented'
			end
		end
	end
end