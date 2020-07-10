require "./lib/board.rb"

describe Board do
  
  describe "#unoccupied?" do
    it "returns true if position is occupied by NilPiece" do
      test = Board.new()
      expect(test.unoccupied?([3,3])).to be true
      expect(test.unoccupied?([0,3])).to be false
    end
  end
end
