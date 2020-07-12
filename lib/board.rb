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

  def possible_moves(start_pos)
    piece = @board[start_pos[0]][start_pos[1]]
    piece.moves = []
    range = piece.move_range
    case piece
    when Rook, Queen, Bishop
      (1..7).each do |val|
        piece.moves << step_move(start_pos, range, val)
      end
    when King, Knight, Pawn
      piece.moves << step_move(start_pos, range, 1)
    end
    piece.moves = piece.moves.flatten!.each_slice(2).to_a
    valid_moves(start_pos, piece.moves).uniq
  end

  def step_move(start_pos, range, multiplier)
    move_block = []
    range.each_with_index do |dir_arr, index|
      move_block << start_pos.map.with_index { |v, i| v += dir_arr[i] * multiplier }
    end
    move_block.each_with_index do |arr, idx|
      if !unoccupied?(arr)
        range.delete_at(idx)
      end
    end
    move_block.flatten.each_slice(2).to_a
  end

  def valid_moves(start_pos, all_moves)
    all_moves.select { |arr| arr if (arr.all? { |val| (val >= 0 && val < 8) }) } #within board
      .select { |arr| opponent?(start_pos, arr) } #is opponent?
      .reject { |arr| arr.empty? }
  end

  def unoccupied?(position)
    @board[position[0]][position[1]].class == NilPiece
  end

  def opponent?(start_pos, end_pos)
    @board[start_pos[0]][start_pos[1]].color != @board[end_pos[0]][end_pos[1]].color
  end

  def move(start_pos, end_pos)
    # Move piece
    piece = @board[start_pos[0]][start_pos[1]]
    if possible_moves(start_pos).any? { |arr| arr == end_pos }
      @board[end_pos[0]][end_pos[1]] = piece
      @board[start_pos[0]][start_pos[1]] = NilPiece.new("")
    end
  end
end
