class AddGameDescriptionModel < ActiveRecord::Migration
    def change
        create_table :game_descriptions do |t|
            t.timestamps
        end
    end
end
