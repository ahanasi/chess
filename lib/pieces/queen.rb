require_relative "piece.rb"
require_relative "sliding.rb"

class Queen < Piece
  include SlidingPiece

  def initialize(color)
    @move_range = [[0, 1], [0, -1], [1, 0], [-1, 0], [1, 1], [1, -1], [-1, 1], [-1, -1]]
    @icon = (color == "white") ? "♛" : "♕"
    super
  end
end
