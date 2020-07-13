require "pry"

class Piece
  attr_accessor :color, :moves, :move_range, :icon, :unmoved

  def initialize(color)
    @color = color
    @moves = []
    @unmoved = true
  end
end
