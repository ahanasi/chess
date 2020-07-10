require_relative "piece.rb"
require_relative "sliding.rb"

class Bishop < Piece
  include SlidingPiece

  def initialize(color)
    @move_range = [[1, 1], [1, -1], [-1, 1], [-1, -1]]
    @icon = (color == "white") ? "♝" : "♗"
    super
  end
end