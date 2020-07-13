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
        piece.moves << slide_move(start_pos, range, val)
      end
    when King
      piece.moves << jump_move(start_pos, range, 1)
    when Pawn
      piece.moves << pawn_move(start_pos, range)
    when Knight
      piece.moves << jump_move(start_pos, range, 1)
    end
    piece.moves = piece.moves.flatten!.each_slice(2).to_a
    valid_moves(start_pos, piece.moves).uniq
  end

  def slide_move(start_pos, range, multiplier)
    move_block = jump_move(start_pos, range, multiplier)
    move_block.each_with_index do |arr, idx|
      unless empty_square?(arr)
        range.delete_at(idx)
      end
    end
    move_block.flatten.each_slice(2).to_a
  end

  def jump_move(start_pos, range, multiplier)
    move_block = []
    range.each_with_index do |dir_arr, index|
      move_block << start_pos.map.with_index { |v, i| v += dir_arr[i] * multiplier }
    end
    move_block
  end

  def pawn_move(start_pos, range)
    all_moves = jump_move(start_pos, range, 1).select { |arr| arr if (arr.all? { |val| (val >= 0 && val < 8) }) }

    #Isolate and filter diagonal movements
    diagonal_moves = all_moves.select { |arr| arr[1] != start_pos[1] }
    all_moves = (all_moves - diagonal_moves)
    diagonal_moves.reject! { |arr| (empty_square?(arr) || friendly_fire?(start_pos, arr)) }

    # Remove two-step if pawn has been previously moved
    all_moves.pop() unless @board[start_pos[0]][start_pos[1]].unmoved

    #Add in diagonal attacks if applicable
    all_moves.push(diagonal_moves) unless diagonal_moves.empty?

    #Prevent default movement if position occupied
    all_moves.shift unless empty_square?(all_moves.first)

    return all_moves
  end

  def valid_moves(start_pos, all_moves)
    all_moves.select { |arr| arr if (arr.all? { |val| (val >= 0 && val < 8) }) } #within board
      .select { |arr| !friendly_fire?(start_pos, arr) } #is friendly_fire?
      .reject { |arr| arr.empty? }
  end

  def empty_square?(position)
    @board[position[0]][position[1]].class == NilPiece
  end

  def friendly_fire?(start_pos, end_pos)
    @board[start_pos[0]][start_pos[1]].color == @board[end_pos[0]][end_pos[1]].color
  end

  def move(start_pos, end_pos)
    piece = @board[start_pos[0]][start_pos[1]]

    # Move piece if end position is valid
    if possible_moves(start_pos).any? { |arr| arr == end_pos }
      @board[end_pos[0]][end_pos[1]] = piece
      @board[start_pos[0]][start_pos[1]] = NilPiece.new("")
    end
  end
end
