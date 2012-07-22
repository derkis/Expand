class CleanUpGameSchema < ActiveRecord::Migration
	
	change_table :games do |table|
		table.remove :board, :width, :height, :turn_state, :turn_player_id, :tiles
		table.rename :game_description_id, :template_id
		table.integer :turn_id
	end

end
