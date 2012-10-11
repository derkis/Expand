
module GameSerialization

	def valid_action(user)
		return :code => Turn::Type[:place_piece][:code] if debug_mode
		return :code => Turn::Type[:place_piece][:code] if user.id == self.current_turn.player.user.id
		return :code => Turn::Type[:no_action][:code]
	end

	def player_index_for(current_user)
		self.players.index do |player|
			player.user_id == current_user.id
		end
	end

	TEST_PLAYER_ID = 1
	def debug_mode
		# self.players.include? do |player| # not sure why this isn't work, works fine the test script
		# 	player.user_id == TEST_PLAYER_ID
		# end 
		
		return false if self.players.each do |player|
			return true if player.user_id == TEST_PLAYER_ID
		end	
  end

  def current_player_index
    self.current_turn.player.index
  end
 
end
