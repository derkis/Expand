class AddHasBegunToGame < ActiveRecord::Migration
  def self.up
    add_column :games, :has_begun, :boolean
  end

  def self.down
    remove_column :games, :has_begun
  end
end
