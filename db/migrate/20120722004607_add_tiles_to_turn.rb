class AddTilesToTurn < ActiveRecord::Migration
  def change
    add_column :turns, :tiles, :string
  end
end
