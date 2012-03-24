class GamesController < ApplicationController
  
  before_filter :authenticate_user!
  before_filter :set_last_request_at, :only => :index
  
  def index
    @title = 'portal'
    @online_users = User.where(
      "last_request_at > :time AND NOT email = :email", 
      { :time => 15.minutes.ago, :email => current_user.email }
    ).all
  end
  
  private
  
  def set_last_request_at
    current_user.update_attribute(:last_request_at, Time.now) if user_signed_in?
  end
  
end
