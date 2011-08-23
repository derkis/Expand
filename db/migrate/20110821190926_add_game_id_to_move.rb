class AddGameIdToMove < ActiveRecord::Migration
  def self.up
    add_column :moves, :game_id, :integer
    
    add_index :moves, :game_id
  end

  def self.down
    remove_column :moves, :game_id
  end
end
