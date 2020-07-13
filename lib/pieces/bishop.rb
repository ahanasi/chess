require_relative "piece.rb"

class Bishop < Piece

  def initialize(color)
    @move_range = [[1, 1], [1, -1], [-1, 1], [-1, -1]]
    @icon = (color == "white") ? "♝" : "♗"
    super
  end
end
