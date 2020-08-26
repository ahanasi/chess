# typed: true
require 'sorbet-runtime'
require_relative "piece.rb"

class Bishop < Piece
  extend T::Sig

  sig {params(color: String).void}
  def initialize(color)
    @move_range = [[1, 1], [1, -1], [-1, 1], [-1, -1]]
    @icon = (color == "white") ? "♝" : "♗"
    super
  end
end
