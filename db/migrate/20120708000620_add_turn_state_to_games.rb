class AddTurnStateToGames < ActiveRecord::Migration
  def change
    add_column :games, :turn_state, :int

  end
end
