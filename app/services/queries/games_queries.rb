module GamesQueries

  # returns hash of proposed games/players in the format
  #   game id string => array of players
  # accepts a user model object as a parameter (though it only uses the id)
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

    players_array.group_by { |player| player['game_id'] }
  end

  def self.get_ready_game_for(current_user)
    game = Game.includes([:players]).first(
    	:conditions => [
        'game_id = players.game_id AND proposing_player = players.id
          AND status = ? AND players.user_id = ?', 
          Game::State::Proposed, current_user.id
      ]
    )
    return nil unless game

    players_are_ready = game.players.inject(true) do |is_ready, player| 
      is_ready &&= player.accepted
    end

    other_player_emails = User.includes([:players]).all(
    	:select => :email, 
    	:conditions => ['user_id = players.user_id AND players.game_id = ? AND NOT user_id = ?', game.id, current_user.id]
    ).map(&:email)

    { :game_id => game.id, :other_players => other_player_emails } if players_are_ready
  end

  def self.get_started_game_for(current_user)
    Game.includes([:players]).first(
    	:select => :game_id, 
    	:conditions => [
        'status = ? AND game_id = players.game_id 
          AND players.user_id = ?', Game::State::Started, current_user.id
      ]
    )
  end

end