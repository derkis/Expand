class AddIndexToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :index, :integer

  end
end
