require 'games_webservices'
require 'games_helper'

class GamesController < ApplicationController
  
  include GamesWebservices
  include GamesHelper
  
  before_filter :authenticate_user!
  before_filter :redirect_user_to_started_game, :only => :index
  before_filter :verify_user_in_game, :only => [:update, :show]
  after_filter :set_last_request_at, :only => [:index, :create, :update, :show]
  
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
    logger.debug "   DEBUG: show action name: #{action_name}"
    @game = Game.find(params[:id])
  end

  def derp
    started_game = Game.get_started_game_for(current_user)
    respond_to do |format|
      format.json { render :json => started_game.id.to_json }
      format.all { not_found() }
    end
  end
  
end
