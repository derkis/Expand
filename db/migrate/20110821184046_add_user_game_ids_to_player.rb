class AddUserGameIdsToPlayer < ActiveRecord::Migration
  def self.up
    add_column :players, :user_id, :integer
    add_column :players, :game_id, :integer
    
    add_index :players, :user_id
    add_index :players, :game_id
    add_index :players, [:user_id, :game_id], :unique => true
  end

  def self.down
    remove_column :players, :game_id
    remove_column :players, :user_id
  end
end
