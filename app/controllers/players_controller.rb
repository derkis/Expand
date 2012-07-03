class PlayersController < ApplicationController
  
  before_filter :authenticate_user!
  after_filter :set_last_request_at
  
  def update
    @player = Player.find(params[:id])
    logger.debug("  DEBUG: player before: #{@player.accepted}");
    @player.update_attributes(params[:player])
    logger.debug("  DEBUG: player after: #{Player.find(params[:id]).accepted}");
    render :nothing => true
  end
  
end
