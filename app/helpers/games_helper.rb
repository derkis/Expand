module GamesHelper
   # @param [Game] game
   def getBoardArrayFromGame(game)
        board = Array.new(game.game_description.height) {Array.new}

        r = 0
        ix = 0

        while r < game.game_description.height
          c = 0

          while c < game.game_description.width
            board[r][c] = game.board[ix]
            ix = ix + 1
            c = c + 1
          end
          r = r + 1
        end

        return board
   end
end
