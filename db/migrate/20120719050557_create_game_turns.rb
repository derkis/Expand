class CreateGameTurns < ActiveRecord::Migration
  def change
    create_table :game_turns do |t|
      t.integer :game_id
      t.integer :player_id
      t.integer :turn_num
      t.integer :turn_state
      t.integer :active_player_id
      t.text :action_taken

      t.timestamps
    end
  end
end
