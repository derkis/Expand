require 'games_webservices'
require 'games_helper'

class GamesController < ApplicationController
  
  include GamesWebservices
  include GamesHelper
  
  before_filter :authenticate_user!
  before_filter :verify_user_in_game, :only => [:update, :show]
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
  
  def update
    @game = Game.find(params[:id])
    @game.update_attributes(params[:game])
    
    respond_to do |format|
      format.json { render :json => @game.id.to_json }
      format.all { not_found() }
    end
  end
  
  def show
    @game = Game.find(params[:id])
  end
  
end
