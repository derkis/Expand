class RemoveTilesFromTurn < ActiveRecord::Migration
  def up
    remove_column :turns, :tiles
  end

  def down
  end
end