class TestGameController < ApplicationController
      
    include GamesHelper

    layout "game"
     
    before_filter :authenticate_user!

    def start
        # SETUP GAME DESCRIPTION
        @description = GameDescription.find(1)

        # SETUP TEST GAME
        @game = Game.new({"proposing_player" => 1, 
                          "players_attributes"=>{
                            "1"=>{"user_id"=>1}, 
                            "2"=>{"user_id"=>2}, 
                            "3"=>{"user_id"=>3},
                            "4"=>{"user_id"=>4}
                            }
                         }
                        )
        @game.start
        @game.save

        #@game.refresh_player_tiles

        # REDIRECT TO START GAME
        redirect_to "/testContinue"
    end

    def play
        @game = Game.find(session[:game_id])
        @title = 'playing game #{@game.id}'
        #Create mock game just for initial display...
        @board = getBoardArrayFromGame(@game)

        render("games/game")
    end
end
