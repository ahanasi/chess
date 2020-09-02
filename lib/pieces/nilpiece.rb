# typed: true
require 'sorbet-runtime'
require_relative "piece.rb"

class NilPiece < Piece
  extend T::Sig

  sig {params(color: String).void}
  def initialize(color)
    super
    @icon = "."
  end
end
