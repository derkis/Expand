class PlayersController < ApplicationController
  
  before_filter :authenticate_user!
  after_filter :set_last_request_at
  
  def update
    @player = Player.find(params[:id])
    @player.update_attributes(params[:player])

    if(params.has_key?(:canceled) and params[:canceled])
      @player.game.remove_player(@player)
    end

    respond_to do |format|
      format.json { render :json => @player.game_id.to_json() }
      format.all { not_found() }
    end
  end
  
end
