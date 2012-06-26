class AddAcceptedStateToPlayer < ActiveRecord::Migration
  def change
    add_column :players, :accepted, :boolean

  end
end
