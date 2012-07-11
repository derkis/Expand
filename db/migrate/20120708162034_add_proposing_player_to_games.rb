class AddProposingPlayerToGames < ActiveRecord::Migration
  def change
    add_column :games, :proposing_player, :integer
  end
end
