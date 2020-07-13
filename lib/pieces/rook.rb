require_relative "piece.rb"

class Rook < Piece

  def initialize(color)
    @move_range = [[0, 1], [0, -1], [1, 0], [-1, 0]]
    @icon = (color == "white") ? "♜" : "♖"
    super
  end
end
