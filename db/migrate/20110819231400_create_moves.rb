class CreateMoves < ActiveRecord::Migration
  def self.up
    create_table :moves do |t|
      t.string :type
      t.string :contents

      t.timestamps
    end
  end

  def self.down
    drop_table :moves
  end
end
