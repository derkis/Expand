class AddWidthToGames < ActiveRecord::Migration
  def change
    add_column :games, :width, :integer

  end
end
