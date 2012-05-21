class GamesController < ApplicationController
  
  before_filter :authenticate_user!
  before_filter :set_last_request_at
  
  def index
    @title = 'portal'
    @game = Game.new
    @game.players.build
    @online_users = get_online_users
  end
  
  def online_users
    @online_users = get_online_users
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
