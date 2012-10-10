module GamesHelper
  
  def verify_user_in_game
    redirect_to :portal unless current_user.can_view_game?(params[:id])
  end

  def redirect_user_to_started_game
    game = GamesQueries.get_started_game_for(current_user)
    redirect_to game if game
  end

end
