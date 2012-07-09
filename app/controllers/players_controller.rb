class PlayersController < ApplicationController
  
  before_filter :authenticate_user!
  after_filter :set_last_request_at
  
  def update
    @player = Player.find(params[:id])
    @player.update_attributes(params[:player])
    
    respond_to do |format|
      format.json { render :json => @player.to_json }
      format.all { not_found() }
    end
  end
  
end