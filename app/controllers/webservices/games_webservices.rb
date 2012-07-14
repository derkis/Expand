module GamesWebservices
  
  def proposed_games
    proposed_games = Game.get_proposed_games_for(current_user)
    respond_to do |format|
      format.json { render :json => proposed_games.to_json }
      format.all { not_found() }
    end
  end

  def ready_games
    ready_game = Game.get_ready_game_for(current_user)
    respond_to do |format|
      format.json { render :json => ready_game.to_json }
      format.all { not_found() }
    end
  end
  
  def started_games
    started_game = Game.get_started_game_for(current_user)
    respond_to do |format|
      format.json { render :json => started_game.id.to_json }
      format.all { not_found() }
    end
  end

end
