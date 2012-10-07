module Engine

	def self.interpret_turn(game, turn_update)
		@@turn_operations ||= Hash.new.tap do |turn_operations|
			Turn.type.each do |key, value|
				turn_operations[key] = Engine.operation_for_key(key)
			end
		end

		current_turn = game.current_turn
		Turn.Type[turn_update['turn_type'].intern]
		game.current_turn.update_attributes(turn_update)		
	end

	def self.operation_for_key(key)
		case key
		
		when :no_action
			return lambda do |current_turn, turn_update|
				raise 'Engine attempted to parse a no_action turn'
			end
		
		when :place_piece
			return lambda do |current_turn, turn_update|
				row, column = turn_update['row'], turn_update['column']
				current_turn.board 
			end 
		
		when :start_company
			return lambda do |current_turn, turn_update|
				raise 'start_company not implemented'
			end

		when :purchase_stock
			return lambda do |current_turn, turn_update|
				raise 'purchase_stock not implemented'
			end

		when :trade_stock
			return lambda do |current_turn, turn_update|
				raise 'trade_stock not implemented'
			end

		when :merge_order
			return lambda do |current_turn, turn_update|
				raise 'merge_order not implemented'
			end

		when :debug_mode 
			return lambda do |current_turn, turn_update|
				raise 'debug_mode not implemented'
			end

		end
	
	end

end