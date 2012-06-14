class AddUserAndGameIdsToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :game_id, :integer
    add_column :players, :user_id, :integer
  end
end
