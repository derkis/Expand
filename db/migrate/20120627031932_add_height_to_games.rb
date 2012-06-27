class AddHeightToGames < ActiveRecord::Migration
  def change
    add_column :games, :height, :integer

  end
end
