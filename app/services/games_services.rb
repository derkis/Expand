require 'games_queries'

module GamesServices
  
  include GamesQueries

  def proposed_games
    proposed_games = GamesQueries.get_proposed_games_for(current_user)
    respond_to do |format|
      format.json { render :json => proposed_games.to_json }
      format.all { not_found() }
    end
  end

  def ready_games
    ready_game = GamesQueries.get_ready_game_for(current_user)
    respond_to do |format|
      format.json { render :json => ready_game.to_json }
      format.all { not_found() }
    end
  end
  
  def started_games
    started_game = GamesQueries.get_started_game_for(current_user)
    respond_to do |format|
      format.json { render :json => (started_game) ? started_game.id.to_json : nil.to_json }
      format.all { not_found() }
    end
  end

end
