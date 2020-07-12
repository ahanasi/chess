require_relative "piece.rb"

class King < Piece
  def initialize(color)
    @move_range = [[0, 1], [0, -1], [1, 0], [-1, 0], [1, 1], [1, -1], [-1, 1], [-1, -1]]
    @icon = (color == "white") ? "♚" : "♔"
    super
  end
end