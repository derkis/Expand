class GamesController < ApplicationController
  
  before_filter :authenticate_user!
  after_filter :set_last_request_at, :except => :user_delta
    
  def index
    @title = 'portal'
    @game = Game.new
    logger.debug " DEBUG: INDEX -- #{@game.id}"
    @game.players.build
    @online_users = get_users_since(15.minutes.ago)
  end
  
  def create
    logger.debug "  DEBUG: games params #{params[:game]}"
    @game = Game.new(params[:game])
    logger.debug "  DEBUG: game #{@game.id} players #{@game.players}"
    @game.save    
    logger.debug "  DEBUG: players in game, #{@game.players}"
    render :nothing => true
  end
  
  def users_online
    user_delta = get_users_since(15.minutes.ago)    
    respond_to do |format| 
      format.html { redirect_to :portal }
      format.json { render :json => user_delta.to_json(:only => [:id, :email]) }
    end
  end
  
  def proposed_games
    proposed_games = get_proposed_games()
    respond_to do |format|
      format.json { render :json => proposed_games.to_json }
    end
  end
  
  private
  
  def get_users_since(time)
    User.find(:all, :conditions => [ "last_request_at > ? AND NOT email = ?", time, current_user.email ], :order => :id)
  end
  
  def get_proposed_games
    Game.includes([:players]).where(['status = ? AND players.user_id = ?', Game::PROPOSED, current_user.id])
  end
  
  def set_last_request_at
    current_user.update_attribute(:last_request_at, Time.now) if user_signed_in?
  end
  
end
