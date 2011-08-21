class AddCashStockToPlayer < ActiveRecord::Migration
  def self.up
    add_column :players, :cash, :string
    add_column :players, :stock, :string
  end

  def self.down
    remove_column :players, :stock
    remove_column :players, :cash
  end
end
