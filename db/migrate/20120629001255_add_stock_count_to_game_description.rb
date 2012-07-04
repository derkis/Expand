class AddStockCountToGameDescription < ActiveRecord::Migration
  def change
    add_column :game_descriptions, :stock_count, :integer

  end
end
