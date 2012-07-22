class AddTileCountToTemplate < ActiveRecord::Migration
  def change
    add_column :templates, :tile_count, :integer
  end
end
