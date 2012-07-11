require 'games_webservices'

class GamesController < ApplicationController
  
  include GamesWebservices
  
  before_filter :authenticate_user!
  after_filter :set_last_request_at
  
  def index
    @title = 'portal'
    @game = Game.new
    @game.players.build
    @online_users = current_user.get_other_users_since(15.minutes.ago)
  end
  
  def create
    if(current_user.can_create_game?)
      @game = Game.new(params[:game])
      @game.save
    else
      logger.debug("You've already proposed a game") # TODO: this action needs to render JSON
    end
    render :nothing => true
  end
  
end
