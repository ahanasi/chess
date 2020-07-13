require_relative "piece.rb"

class Pawn < Piece
  def initialize(color)
    @move_range = [[1,0], [1,1], [1,-1], [2,0]]
    @icon = (color == "white") ? "♟︎" : "♙"
    super
  end
end
