require "./lib/game.rb"

describe Game do
  describe "#ep_pawn" do
    xit "returns an array of en_passant capturable pawns" do
      test = Game.new()
      test.board.board[3][2] = Pawn.new("black")
      test.board.board[3][3] = Pawn.new("white")
      test.current_piece = test.get_piece([3, 2])
      test.current_move = [[3, 2], [3, 3]]
      test.is_white = false
      expect(test.ep_pawn()).not_to be true
    end
  end

  describe "#check" do
    xit "returns the position of the king in check" do
      test = Game.new()
      test.board.board[4][4] = King.new("white")
      test.board.board[4][3] = Rook.new("black")
      test.current_piece = test.get_piece([4, 3])
      test.current_move = [[4, 2], [4, 3]]
      expect(test.check()).to match_array([[4,4]])
    end

    xit "ignores friendly fire" do
      test = Game.new()
      test.board.board[4][4] = King.new("white")
      test.board.board[4][3] = Rook.new("white")
      test.current_piece = test.get_piece([4, 3])
      test.current_move = [[4, 2], [4, 3]]
      expect(test.check()).to match_array([])
    end

    it "works for pawns" do
      test = Game.new()
      test.board.board[4][4] = King.new("black")
      test.board.board[3][3] = Pawn.new("white")
      test.current_piece = test.get_piece([3, 3])
      test.current_move = [[2, 3], [3, 3]]
      expect(test.check()).to match_array([[4,4]])
    end
  end
end
