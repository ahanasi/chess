require_relative "piece.rb"

class NilPiece < Piece
  def initialize(color)
    @move_range = []
    @icon = "."
    super
  end
end
