class GamesController < ApplicationController
  
  before_filter :authenticate_user!
  before_filter :set_last_request_at
  
  def index
    @title = 'portal'
    @game = Game.new
    @game.players.build
    @online_users = get_online_users()
  end
  
  def create
    logger.debug "  DEBUG: games params #{params[:game]}"
    @game = Game.new(params[:game])
    @game.save
    logger.debug "  DEBUG: players in game, #{@game.players}"
  end
  
  def online_users
    @online_users = get_online_users()    
    respond_to do |format| 
      format.html { redirect_to :portal }
      format.json { render :json => @online_users.to_json(:only => [:id, :email]) }
    end
  end
  
  private
  
  def get_online_users
    User.where(
      "last_request_at > :time AND NOT email = :email", 
      { :time => 15.minutes.ago, :email => current_user.email }
    ).all
  end
  
  def set_last_request_at
    current_user.update_attribute(:last_request_at, Time.now) if user_signed_in?
  end
  
end
