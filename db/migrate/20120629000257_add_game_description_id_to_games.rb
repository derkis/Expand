class AddGameDescriptionIdToGames < ActiveRecord::Migration
  def change
    add_column :games, :game_description_id, :integer

  end
end
