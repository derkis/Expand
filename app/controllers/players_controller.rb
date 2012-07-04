class PlayersController < ApplicationController
  
  before_filter :authenticate_user!
  after_filter :set_last_request_at
  
  def update
    @player = Player.find(params[:id])
    logger.debug("  DEBUG: player before: #{@player}");
    @player.update_attributes(params[:player])
    logger.debug("  DEBUG: player after: #{Player.find(params[:id])}");
    
    respond_to do |format|
      format.json { render :json => @player.to_json }
      format.all { not_found() }
    end
  end
  
end
