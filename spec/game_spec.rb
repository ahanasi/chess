require "./lib/game.rb"

describe Game do
  describe "#ep_pawn" do
    it "returns an array of en_passant capturable pawns" do
      test = Game.new()
      test.board.board[3][2] = Pawn.new("black")
      test.board.board[3][3] = Pawn.new("white")
      test.current_piece = test.get_piece([3, 2])
      test.current_move = [[3, 2], [3, 3]]
      test.turn = 1
      expect(test.ep_pawn()).not_to be true
    end
  end

  describe "#check" do
    it "returns the position of the king in check" do
      test = Game.new()
      test.board.board[4][4] = King.new("white")
      test.board.board[4][3] = Rook.new("black")
      test.board.board[4][3].moves = test.board.possible_moves([4, 3])
      test.turn = 1
      test.current_set = [test.board.board[4][3]]
      expect(test.check(test.current_set)).to match_array([4, 4])
    end

    it "ignores friendly fire" do
      test = Game.new()
      test.board.board[4][4] = King.new("white")
      test.board.board[4][3] = Rook.new("white")
      test.current_set = [test.board.board[4][3]]
      expect(test.check(test.current_set)).to be false
    end

    it "works for pawns" do
      test = Game.new()
      test.board.board[4][4] = King.new("black")
      test.board.board[3][3] = Pawn.new("white")
      test.board.board[3][3].moves = test.board.possible_moves([3, 3])
      test.current_set = [test.board.board[3][3]]
      expect(test.check(test.current_set)).to match_array([4, 4])
    end
  end

  describe "#promotion" do

    test = Game.new()
    test.board.board[7][1] = Pawn.new("white")
    test.current_piece = test.board.board[7][1]
    test.current_move = [[],[7,1]]
    test.turn = 2  

    it "promotes the pawn to a new Queen" do
      orig_stdin = $stdin 
      $stdin = StringIO.new('Q') 
      expect(test.promotion().class).to be Queen
    end

    it "promotes the pawn to a new Rook" do
      orig_stdin = $stdin 
      $stdin = StringIO.new('R') 
      expect(test.promotion().class).to be Rook
    end

    it "promotes the pawn to a new Bishop" do
      orig_stdin = $stdin 
      $stdin = StringIO.new('B') 
      expect(test.promotion().class).to be Bishop
    end

    it "promotes the pawn to a new Knight" do
      orig_stdin = $stdin 
      $stdin = StringIO.new('K') 
      expect(test.promotion().class).to be Knight
    end

    it "does not promote pawn in wrong position" do
      test = Game.new()
      test.board.board[7][1] = Pawn.new("black")
      test.current_piece = test.board.board[7][1]
      test.current_move = [[],[7,1]]
      test.turn = 3
      expect(test.promotion()).to be false
    end

  end
end
