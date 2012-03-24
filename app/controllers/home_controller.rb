class HomeController < ApplicationController

  def index    
    @title = 'Home'
    @user = User.new
  end

end
