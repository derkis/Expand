module GamesQueries

  def self.get_proposed_games_for(current_user)
    players_array = Player.includes([:game]).all(
    	:conditions => ['user_id = ? AND games.status = ?', current_user.id, Game::PROPOSED]
    )

    games_string = players_array.inject(' AND (') do
    	|string, player| string += "p.game_id = #{player.game_id} OR "
    end
    
    players_array = ActiveRecord::Base.connection.execute(
      'SELECT 
      	DISTINCT p.id AS player_id, p.game_id AS game_id, p.accepted AS accepted, u.email AS email 
        FROM users u, players p 
        WHERE u.id = p.user_id' + ((games_string.length > 6) ? (games_string[0..-5]) + ')' : '')
    );

    players_array.size.times do |i|
      players_array[i] = players_array[i].delete_if { |key, value| key.kind_of? Integer } 
    end

    players_array.group_by { |player| player['game_id'] }
  end

  def self.get_ready_game_for(current_user)
    game = Game.includes([:players]).first(
    	:conditions => ['game_id = players.game_id AND proposing_player = players.id AND status = ? AND players.user_id = ?', Game::PROPOSED, current_user.id]
    )
    return nil unless game

    players_are_ready = game.players.inject(true) do
    	|is_ready, player| is_ready &&= player.accepted
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
    	:conditions => ['status = ? AND game_id = players.game_id AND players.user_id = ?', Game::STARTED, current_user.id]
    )
  end

end