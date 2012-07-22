class RenameGameDescriptionToTemplates < ActiveRecord::Migration
	def change
		rename_table :game_descriptions, :templates
	end
end
