class Rook < Piece
  include SlidingPiece

  def initialize(color)
    @move_range = [[0, 1], [0, -1], [1, 0], [-1, 0]]
    @icon = (color == "white") ? "♜" : "♖"
    super
  end
end