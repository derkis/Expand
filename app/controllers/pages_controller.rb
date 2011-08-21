class PagesController < ApplicationController
  def home
    if signed_in?
      redirect_to :lobby
    else
      @title = 'Home'
    end
  end

  def contact
    @title = 'Contact'
  end

  def about
    @title = 'About'
  end
end
