Dir["./lib/pieces/*.rb"].each { |file| require file }
require_relative "display.rb"
require "pry"

class Board
  include Display
  attr_accessor :board

  def initialize
    @board = Array.new(8) { Array.new(8, NilPiece.new("")) }
    setup_board()
  end

  def unoccupied?(position)
    @board[position[0]][position[1]].class == NilPiece
  end

  def move(start_pos, end_pos)
    
  end
end