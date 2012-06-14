class HomeController < ApplicationController

  before_filter :redirect_signed_in_user
  
  def index    
    @title = 'Home'
    @user = User.new
  end

  private
  
  def redirect_signed_in_user
    redirect_to :portal if user_signed_in?
  end
  
end
