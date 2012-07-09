class AddTurnPlayerIdToGames < ActiveRecord::Migration
  def change
    add_column :games, :turn_player_id, :int

  end
end
