# typed: true
require "sorbet-runtime"

class Piece
  extend T::Sig

  attr_accessor :color, :moves, :move_range, :icon, :unmoved

  sig { params(color: String).void }
  def initialize(color)
    @color = T.let(color, String)
    @moves = T.let([], T::Array[T::Array[Integer]])
    @unmoved = T.let(true, T::Boolean)
    @icon = T.let("", String)
    @move_range = T.let([], T::Array[T::Array[Integer]])
  end
end
