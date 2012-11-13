module GamesQueries

  # returns hash of proposed games/players in the format
  #   game id string => array of players
  # accepts a user model object as a parameter
  def self.get_proposed_games_for(current_user)
    # finds players in proposed gams which match this user's id
    proposed_game_players_conditions = { :conditions => ['user_id = ? AND games.status = ?', current_user.id, Game::State::Proposed] }
    proposed_game_players = Player.includes([:game]).all(proposed_game_players_conditions)

    # return an empty hash if there are no proposed games with a player that matches this user
    return {} if proposed_game_players.count == 0

    # otherwise, build up the appropriate query to format the data
    games_string = proposed_game_players.inject('') do
    	|string, player| string += "p.game_id = #{player.game_id} OR "
    end
    games_string = games_string[0..-5] # truncate the dangling OR

    # gets all players in each proposed game proposed games so that they can be displayed client side
    players_array_query = 
      "SELECT DISTINCT p.id AS player_id, p.game_id AS game_id, p.accepted AS accepted, u.email AS email " +
        "FROM users u, players p WHERE u.id = p.user_id AND (#{games_string})"

    players_array = ActiveRecord::Base.connection.execute(players_array_query);
    players_array.size.times do |i|
      players_array[i] = players_array[i].delete_if { |key, value| key.kind_of? Integer } 
    end

    return players_array.group_by { |player| player['game_id'] }
  end

  # returns a hash containing the id of the game which is ready to be started, for initiator's approval
  #   and a list of the emails of the other players, for display client-side
  # accepts a user model object as a parameter 
  def self.get_ready_game_for(current_user)
    ready_game_query_format = 'game_id = players.game_id AND proposing_player = players.id AND status = ? AND players.user_id = ?'
    # fetch a game model where status is ready and this user was the proposing player
    ready_game_conditions = [ ready_game_query_format, Game::State::Ready, current_user.id ]
    ready_game = Game.includes([:players]).first(:conditions => ready_game_conditions)
    return nil unless ready_game

    # iterating over the game's players, returning the emails of everyone still in the game who is not the proposing player
    other_players_conditions = [ 'game_id = ? AND user_id <> ?', ready_game.id, current_user.id ]
    other_players_emails = Player.all(:conditions => other_players_conditions).map(&:email)

    return { :game_id => ready_game.id, :other_players => other_players_emails }
  end

  def self.get_started_game_for(current_user)
    started_game_query_format = 'status = ? AND game_id = players.game_id AND players.user_id = ?'
    started_game_conditions = [ started_game_query_format, Game::State::Started, current_user.id ]
    started_game = Game.includes([:players]).first(:select => :game_id, :conditions => started_game_conditions)
    return started_game
  end

end