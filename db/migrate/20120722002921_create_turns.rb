class CreateTurns < ActiveRecord::Migration
  def change
    create_table :turns do |t|
      t.integer :game_id
      t.integer :player_id
      t.integer :number
      t.string :board
      t.text :data
      t.text :action

      t.timestamps
    end
  end
end
