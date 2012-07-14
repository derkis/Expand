module GamesHelper
  
  def verify_user_in_game
    redirect_to :portal unless current_user.can_view_game?(params[:id])
  end

  def redirect_user_to_started_game
    game = Game.get_started_game_for(current_user)
    redirect_to game if game
  end
    
  # @param [Game] game
  def getBoardArrayFromGame(game)
    board = Array.new(game.game_description.height) {Array.new}

    r = 0
    ix = 0

    while r < game.game_description.height
      c = 0

      while c < game.game_description.width
        board[r][c] = {:state => game.board[ix], :row => r, :column => c}
        ix = ix + 1
        c = c + 1
      end
      r = r + 1
    end

    return board
  end
end
