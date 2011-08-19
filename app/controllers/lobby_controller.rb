class LobbyController < ApplicationController
  def lobby
    @title = 'Lobby'
    @online_users = User.find_all_by_is_online(true)
  end
end
