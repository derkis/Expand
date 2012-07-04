class AddWidthAndHeightToGameDescriptions < ActiveRecord::Migration
  def change
    add_column :game_descriptions, :width, :integer

    add_column :game_descriptions, :height, :integer

  end
end
