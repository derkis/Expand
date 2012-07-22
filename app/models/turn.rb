# == Schema Information
#
# Table name: turns
#
#  id         :integer         not null, primary key
#  game_id    :integer
#  player_id  :integer
#  number     :integer
#  board      :string(255)
#  data       :text
#  action     :text
#  created_at :datetime        not null
#  updated_at :datetime        not null
#  tiles      :string(255)
#

class Turn < ActiveRecord::Base

	belongs_to :game
	belongs_to :player

	attr_accessible :game_id, :player_id, :number, :board, :tiles 

	def self.create_first_turn_for(game, starting_player_id)
		turn = Turn.create({
			:game_id => game.id,
			:player_id => starting_player_id,
			:number => 0,
			:board => 'e' * game.board_area,
			:tiles => 'tiles should go here'
		})
		turn.refresh_player_tiles
		turn
	end

	def refresh_player_tiles
		@tile_counts = Hash.new(0)

		self.board.chars.to_a.each do |t|
			pid = t.ord - 48
			if pid >= 0 && pid <= 9
				@tile_counts[pid] += 1 
			end
		end

		unused_tiles = find_unused_tile_indices.shuffle!

		pid = 0
		self.game.players.each do |p|
			puts "Player Distribute: #{pid}"
			while @tile_counts[pid] < 6  
				ix = unused_tiles.pop
				board[ix] = pid.to_s
				@tile_counts[pid] += 1
			end 
			pid += 1
		end
	end

	def find_unused_tile_indices
    tiles = Array.new
    self.board.chars.to_a.each_with_index { |c, i| tiles.push(i) if c == 'e' }
    tiles
  end

end
