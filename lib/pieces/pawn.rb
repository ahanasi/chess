# typed: true
require "sorbet-runtime"
require_relative "piece.rb"

class Pawn < Piece
  extend T::Sig

  attr_accessor :cant_ep

  sig { params(color: String).void }
  def initialize(color)
    @move_range = (color == "white") ? [[1, 0], [1, 1], [1, -1], [2, 0]] : [[-1, 0], [-1, 1], [-1, -1], [-2, 0]]
    @icon = (color == "white") ? "♟︎" : "♙"
    @cant_ep = T.let(false, T::Boolean)
    super
  end
end
