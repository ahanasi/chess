# typed: ignore
require "./lib/board.rb"

describe Board do
  describe "#possible_moves" do
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

    it "gives all possible moves for a Knight from a given start position" do
      test = Board.new()
      test.board[2][3] = Knight.new("white")
      expect(test.possible_moves([2, 3])).to match_array([[3, 5], [3, 1], [4, 4], [4, 2]])
    end

    it "gives all possible moves for a White Knight from default start position" do
      test = Board.new
      test.board[0][1] = Knight.new("white")
      expect(test.possible_moves([0, 1])).to match_array([[2, 0], [2, 2]])
    end

    it "gives all possible moves for a Black Knight from default start position" do
      test = Board.new
      expect(test.possible_moves([7, 1])).to match_array([[5, 0], [5, 2]])
    end

    it "gives all possible moves for a Pawn from default start position" do
      test = Board.new()
      expect(test.possible_moves([1, 0])).to match_array([[2, 0], [3, 0]])
    end

    it "gives all possible moves for a Pawn surrounded by empty squares" do
      test = Board.new()
      test.board[2][3] = Pawn.new("white")
      test.board[2][3].unmoved = false
      expect(test.possible_moves([2, 3])).to match_array([[3, 3]])
    end

    it "all possible moves includes diagonal attack for a Pawn with enemy at one diagonal" do
      test = Board.new()
      test.board[2][3] = Pawn.new("white")
      test.board[3][4] = Pawn.new("black")
      test.board[3][2] = Pawn.new("white")

      test.board[2][3].unmoved = false
      test.board[3][4].unmoved = false
      test.board[3][2].unmoved = false
      expect(test.possible_moves([2, 3])).to match_array([[3, 3], [3, 4]])
    end

    it "gives all possible moves for a Queen from a given start position" do
      test = Board.new()
      test.board[1][3] = NilPiece.new("")
      test.display_board
      expect(test.possible_moves([0, 3])).to match_array([[1, 3], [2, 3], [3, 3], [4, 3], [5, 3], [6, 3]])
    end

    it "gives all possible moves for a Bishop from a given start position" do
      test = Board.new()
      test.board[6][3] = NilPiece.new("")
      test.display_board
      expect(test.possible_moves([7, 2])).to match_array([[6, 3], [5, 4], [4, 5], [3, 6], [2, 7]])
    end
  end

  describe "#empty_square?" do
    it "returns true if position is occupied by NilPiece" do
      test = Board.new()
      expect(test.empty_square?([3, 3])).to be true
      expect(test.empty_square?([0, 3])).to be false
    end
  end

  describe "#move" do
    it "moves a chess piece from start_pos to end_pos" do
      test = Board.new()
      test_piece = test.board[0][0]
      test.move([0, 0], [3, 3],"white")
      expect(test.board[3][3].class).to eql(NilPiece)
      test.move([1, 0], [1, 1],"white")
      test.display_board
      expect(test.board[1][1].class).to eql(Pawn)
    end
  end

  describe "#initialize_moves" do
    it "sets the valid moves array for each piece on board" do
      test = Board.new()
      test.initialize_moves()
      test_piece = test.board[0][0]
      expect(test_piece.moves).to match_array([])
      test_piece = test.board[1][0]
      expect(test_piece.moves).to match_array([[2,0],[3,0]])
    end
  end
end
