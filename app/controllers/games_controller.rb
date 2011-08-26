class GamesController < ApplicationController
  def new
    @title = 'Lobby'
    @game = Game.new
    @online_users = get_online_users
   
    logger.debug "  DEBUG: online_users, #{@online_users}"
  end
  
  def create
    logger.debug "  DEBUG: games params #{params[:game]}"
    @game = Game.new(params[:game])
    @game.save
    logger.debug "  DEBUG: players in game, #{@game.players}"
    redirect_to game_path(@game.id)
  end
  
  def show
    @title = 'Game'
    logger.debug "  DEBUG: rendering game"
  end
  
  def destroy
    
  end
end
