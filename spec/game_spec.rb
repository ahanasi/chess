require "./lib/game.rb"

describe Game do
  describe "#ep_pawn" do
    it "returns an array of en_passant capturable pawns" do
      test = Game.new()
      test.board.board[3][2] = Pawn.new("black")
      test.board.board[3][3] = Pawn.new("white")
      test.current_piece = test.get_piece([3,2])
      test.current_move = [[3,2],[3,3]]
      test.is_white = false
      expect(test.ep_pawn()).not_to be true
    end
  end
end
