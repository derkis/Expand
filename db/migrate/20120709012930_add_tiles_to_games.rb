class AddTilesToGames < ActiveRecord::Migration
  def change
    add_column :games, :tiles, :string

  end
end
