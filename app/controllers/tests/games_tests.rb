module GamesTests
  
  def new_test_game
    @description = GameDescription.find(1)
    @game = Game.new({ 
      'proposing_player' => 1, 
      'players_attributes' => {
          '1' => { 'user_id' => 1 }, 
          '2' => { 'user_id' => 2 }, 
          '3' => { 'user_id' => 3 },
          '4' => { 'user_id' => 4 }
      }
    })

    @game.start
    @game.save
    redirect_to @game
  end

end