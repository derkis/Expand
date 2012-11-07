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
      @game = Game.create(params[:game])
    else
      logger.debug("You've already proposed a game") # TODO: this needs to be handled somehow
    end
    render :nothing => true
  end
  
  def update
    @game = Game.find(params[:id])
    if(params[:actions])
      Engine.run_action(@game, params[:actions], self)
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

    respond_to do |format|
      format.html do
        @title = 'game'
        @board = @game.board_array # Board layout occurs on server side, but board population occurs on 
        @cur_turn = @game.cur_turn
      end

      format.json do
        render :json => @game.build_json({
          :include => [:template, :players], 
          :methods => [
            :debug_mode,
            :cur_turn_number,
            :cur_player_index,
            { :name => :pass_through, :arguments => [current_user] },
            { :name => :user_player_index, :arguments => [current_user] },
            :last_action,
            :board,
            { :name => :cur_data, :arguments => [current_user] }
          ]
        })
      end
    end
  end
end