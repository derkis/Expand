module GamesHelper
   # @param [Game] game
   def getBoardArrayFromGame(game)
        board = Array.new(game.height) {Array.new}

        r = 0
        ix = 0

        while r < game.height
          c = 0

          while c < game.width
            board[r][c] = 1
            ix = ix + 1
            c = c + 1
          end
          r = r + 1
        end

        return board
   end
end
