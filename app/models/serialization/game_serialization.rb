module GameSerialization

	def valid_action(user)
		return :code => Turn::Type[:place_piece][:code] if debug_mode
		return :code => Turn::Type[:place_piece][:code] if user.id == self.current_turn.player.user.id
		return :code => Turn::Type[:no_action][:code]
	end

	def player_index_for(current_user)
		self.players.each_with_index do |player, index|
		  return index if player.user_id == current_user.id
		end
	end

end