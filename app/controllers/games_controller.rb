require 'games_helper'

class GamesController < ApplicationController

  include GamesHelper

  before_filter :authenticate_user!
  after_filter :set_last_request_at, :except => [:users_online, :proposed_games]
  
  def index
    @title = 'portal'
    @game = Game.new
    @game.players.build
    @online_users = get_users_since(15.minutes.ago)
    @player = Player.find(1)
  end
  
  def create
    logger.debug "  DEBUG: games params #{params[:game]}"
    @game = Game.new(params[:game])
    @game.save    
    logger.debug "  DEBUG: players in game, #{@game.players}"
    render :nothing => true
  end
  
  def play
     @title = 'playing game'
     #Create mock game just for initial display...
     @game = Game.new
     @board = getBoardArrayFromGame(@game)
     render(:game)
  end

  # endpoints
  def users_online
    user_delta = get_users_since(15.minutes.ago)    
    respond_to do |format| 
      format.json { render :json => user_delta.to_json(:only => [:id, :email]) }
      format.all { not_found() }
    end
  end

  def proposed_games
    proposed_games = get_proposed_games()
    logger.debug "  DEBUG: game_players #{proposed_games}"
    respond_to do |format|
      format.json { render :json => proposed_games.to_json }
      format.all { not_found() }
    end
  end

  private
  
  def get_users_since(time)
    User.all(:conditions => [ "last_request_at > ? AND NOT email = ?", time, current_user.email ], :order => :id)
  end

  def get_proposed_games
    players_array = Player.includes([:game]).all(:conditions => ['user_id = ? AND games.status = ?', current_user.id, Game::PROPOSED])
    games_string = players_array.inject(' AND ') { |string, player| string += "p.game_id = #{player.game_id} OR " }
    players_array = ActiveRecord::Base.connection.execute(
      'SELECT DISTINCT p.id AS player_id, p.game_id AS game_id, u.email AS email FROM users u, players p WHERE u.id = p.user_id' + games_string[0..-5]
    );
  
    players_array.size.times do |i|
      players_array[i] = players_array[i].delete_if { |key, value| key.kind_of? Integer } 
    end
    players_array.group_by { |player| player["game_id"] }
   end
  
end
