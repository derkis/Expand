class AddTilesToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :tiles, :string

  end
end
