module GamesHelper
  
  def verify_user_in_game
    redirect_to :portal unless current_user.can_view_game?(params[:id])
  end

  def redirect_user_to_started_game
    game = GamesQueries.get_started_game_for(current_user)
    redirect_to game if game
  end
    
  def get_board_array_from_game(game)
    linear_index = 0
    Array.new(game.template.height){ Array.new }.each do |row_array|
      game.template.width.times do |column|
        row_array[column] = game.current_turn.board[linear_index]
        linear_index += 1
      end
    end
  end
  
end
