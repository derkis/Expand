class AddNameQualityToHotel < ActiveRecord::Migration
  def self.up
    add_column :hotels, :name, :string
    add_column :hotels, :quality, :string
  end

  def self.down
    remove_column :hotels, :quality
    remove_column :hotels, :name
  end
end
