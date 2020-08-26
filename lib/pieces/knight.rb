# typed: true
require "sorbet-runtime"
require_relative "piece.rb"

class Knight < Piece
  extend T::Sig

  sig { params(color: String).void }
  def initialize(color)
    @move_range = [[2, 1], [2, -1], [-2, 1], [-2, -1], [1, 2], [-1, 2], [1, -2], [-1, -2]]
    @icon = (color == "white") ? "♞" : "♘"
    super
  end
end
