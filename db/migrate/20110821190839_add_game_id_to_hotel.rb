class AddGameIdToHotel < ActiveRecord::Migration
  def self.up
    add_column :hotels, :game_id, :integer
    
    add_index :hotels, :game_id
  end

  def self.down
    remove_column :hotels, :game_id
  end
end
