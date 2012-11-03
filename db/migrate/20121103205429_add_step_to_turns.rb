class AddStepToTurns < ActiveRecord::Migration
  def change
    add_column :turns, :step, :integer

  end
end
