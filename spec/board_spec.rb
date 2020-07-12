require "./lib/board.rb"

describe Board do
  xdescribe "#possible_moves" do
    it "gives all possible moves for a Rook from a given start position" do
      test = Board.new()
      test.board[4][4] = Rook.new("white")
      expect(test.possible_moves([4, 4])).to match_array([[4, 5], [4, 3], [5, 4], [3, 4], [4, 6], [4, 2], [6, 4], [2, 4], [4, 7], [4, 1], [4, 0]])
    end

    it "gives all possible moves for a King from a given start position" do
      test = Board.new()
      test.board[2][3] = King.new("white")
      expect(test.possible_moves([2, 3])).to match_array([[2, 4], [2, 2], [3, 4], [3, 3], [3, 2]])
    end
  end

  xdescribe "#unoccupied?" do
    it "returns true if position is occupied by NilPiece" do
      test = Board.new()
      expect(test.unoccupied?([3, 3])).to be true
      expect(test.unoccupied?([0, 3])).to be false
    end
  end

  describe "#move" do
    it "moves a chess piece from start_pos to end_pos" do
      test = Board.new()
      test_piece = test.board[0][0]
      test.move([0, 0], [3, 3])
      expect(test.board[3][3].class).to eql(NilPiece)
      test.move([1, 0], [1, 1])
      test.display_board
      expect(test.board[1][1].class).to eql(Pawn)
    end
  end
end
