require 'games_webservices'
require 'games_tests'
require 'games_helper'

class GamesController < ApplicationController
  
  include GamesWebservices
  include GamesTests
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
    logger.debug "   DEBUG: game: #{@game}"
    @game = Game.find(params[:id])
    respond_to do |format|
      
      format.html do
        @title = 'playing game #{@game.id}'
        #Create mock game just for initial display...
        @board = getBoardArrayFromGame(@game)
      end

      format.json do
        render :json => @game.to_json(:include => :game_description)
      end

    end
    
  end
end
