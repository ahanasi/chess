require_relative "piece.rb"

class Pawn < Piece
  def initialize(color)
    @move_range = [[0, 1], [1,1], [-1,1]]
    @icon = (color == "white") ? "♟︎" : "♙"
    super
  end
end
