module GamesWebservices
  
  def proposed_games
    proposed_games = Game.get_proposed_games_for(current_user)
    logger.debug "  DEBUG: game_players #{proposed_games}"
    respond_to do |format|
      format.json { render :json => proposed_games.to_json }
      format.all { not_found() }
    end
  end
  
end