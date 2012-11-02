
module GameSerialization

	TEST_PLAYER_ID = 1
	def debug_mode
		# self.players.include? do |player| # not sure why this isn't work, works fine the test script
		# 	player.user_id == TEST_PLAYER_ID
		# end 
		
		return false if self.players.each do |player|
			return true if player.user_id == TEST_PLAYER_ID
		end	
	end
 
end
