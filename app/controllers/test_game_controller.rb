class TestGameController < ApplicationController
  
    include GamesHelper
 
    def start
        # SETUP MOCK USERS
        @u1 = User.find(:all, :conditions => {:email => "p1@test.com"})[0]
        @u2 = User.find(:all, :conditions => {:email => "p2@test.com"})[0]
        @u3 = User.find(:all, :conditions => {:email => "p3@test.com"})[0]
        @u4 = User.find(:all, :conditions => {:email => "p4@test.com"})[0]

        # SETUP GAME DESCRIPTION

        @description = GameDescription.find(1)

        # SETUP TEST GAME
        @game = Game.new
        @game.game_description_id = @description.id
        @game.save

        # SETUP PLAYERS
        @p1 = Player.new
        @p1.user_id = @u1.id
        @p1.game_id = @game.id
        @p1.save

        @p2 = Player.new
        @p2.user_id = @u2.id
        @p2.game_id = @game.id
        @p2.save

        @p3 = Player.new
        @p3.user_id = @u3.id
        @p3.game_id = @game.id
        @p3.save

        @p4 = Player.new
        @p4.user_id = @u4.id
        @p4.game_id = @game.id
        @p4.save

        session[:game_id] = @game.id

        # REDIRECT TO START GAME
        redirect_to "/testContinue"
    end

    def play
        @title = 'playing game'
        #Create mock game just for initial display...
        #@board = getBoardArrayFromGame(@game)

        render("games/game")
    end
end
