require 'games_services'
require 'games_tests'
require 'games_helper'
require 'engine'

class GamesController < ApplicationController
  
  include GamesServices
  include GamesHelper
  include GamesTests
  
  before_filter :authenticate_user!
  before_filter :redirect_user_to_started_game, :only => :index
  before_filter :verify_user_in_game, :only => [:update, :show]
  after_filter :set_last_request_at, :only => [:index, :create, :update, :show]
  
  def index
    @title = 'portal'
    @game = Game.new
    @game.players.build
    @online_users = UsersQueries.users_online_for_current_user_since(15.minutes.ago, current_user)
  end
  
  def create
    if(current_user.can_create_game?)
      @game = Game.new(params[:game])
      @game.save
    else
      logger.debug("You've already proposed a game") # TODO: this needs to be handled somehow
    end
    render :nothing => true
  end
  
  def update
    @game = Game.find(params[:id])
    if(params[:game][:turn])
      Engine.interpret_turn(@game, params[:game][:turn], self)
    else
      @game.update_attributes(params[:game])
    end

    respond_to do |format|
      format.json { render :json => @game.id.to_json }
      format.all { not_found() }
    end
  end

  def show
    @game = Game.find(params[:id])
    @player_index = @game.player_index_for(current_user)
    @game.current_user = current_user

    respond_to do |format|
      
      format.html do
        @title = 'game'
        @board = get_board_array_from_game(@game)
      end

      format.json do
        render :json => @game.to_json(
          :include => :template, 
          :methods => [ :current_turn, :valid_action, :debug_mode, :current_player_index ]
        )
      end
    end
  end
end
