class TestGameController < ApplicationController
      
    include GamesHelper

    layout "game"
     
    before_filter :authenticate_user!

    def start
        # SETUP MOCK USERS
        @u1 = User.find(:all, :conditions => {:email => "p1@test.com"})[0]
        if @u1 == nil
            @u1 = User.new(:email => "p1@test.com", :password => "password", :password_confirmation => "password")
            @u1.save
        end
        @u2 = User.find(:all, :conditions => {:email => "p2@test.com"})[0]
        if @u2 == nil
            @u2 = User.new(:email => "p2@test.com", :password => "password", :password_confirmation => "password")
            @u2.save
        end
        @u3 = User.find(:all, :conditions => {:email => "p3@test.com"})[0]
        if @u3 == nil
            @u3 = User.new(:email => "p3@test.com", :password => "password", :password_confirmation => "password")
            @u3.save
        end

        @u4 = User.find(:all, :conditions => {:email => "p4@test.com"})[0]
        if @u4 == nil
            @u4 = User.new(:email => "p4@test.com", :password => "password", :password_confirmation => "password")
            @u4.save
        end

        # SETUP GAME DESCRIPTION
        @description = GameDescription.find(1)

        # SETUP TEST GAME
        @game = Game.new({"proposing_player" => @u1.id, 
                          "players_attributes"=>{
                            @u1.id=>{"user_id"=>@u1.id}, 
                            @u2.id=>{"user_id"=>@u2.id}, 
                            @u3.id=>{"user_id"=>@u3.id},
                            @u4.id=>{"user_id"=>@u4.id}
                            }
                         }
                        )
        @game.start
        @game.save

        @game.refresh_player_tiles

        session[:game_id] = @game.id

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
