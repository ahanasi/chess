# typed: true
require "sorbet-runtime"
Dir["./lib/pieces/*.rb"].each { |file| require file }
require_relative "display.rb"


class Board
  include Display
  include Kernel
  extend T::Sig
  attr_accessor :board, :captured_piece

  sig {void}
  def initialize
    @board = T.let(Array.new(8) { Array.new(8, NilPiece.new("")) }, T::Array[T::Array[Piece]])
    @captured_piece = T.let(NilPiece.new(""), Piece)
    setup_board()
  end

  sig {params(start_pos: T::Array[Integer]).returns(T::Array[T::Array[Integer]])}
  def possible_moves(start_pos)
    piece = @board.fetch(start_pos.fetch(0)).fetch(start_pos.fetch(1))
    piece.moves = []
    range = piece.move_range.dup
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
    piece.moves = valid_moves(start_pos, piece.moves).uniq
  end

  sig  {params(start_pos: T::Array[Integer], range: T::Array[T::Array[Integer]], multiplier: Integer).returns(T::Array[T::Array[Integer]])}
  def slide_move(start_pos, range, multiplier)
    to_delete = []
    move_block = jump_move(start_pos, range, multiplier)
    move_block.each_with_index do |arr, idx|
      unless empty_square?(arr)
        to_delete << idx
      end
    end
    range.reject!.with_index { |e, i| to_delete.include? i }
    move_block.reject { |arr| arr.length < 2 }.flatten.each_slice(2).to_a
  end

  sig  {params(start_pos: T::Array[Integer], range: T::Array[T::Array[Integer]], multiplier: Integer).returns(T::Array[T::Array[Integer]])}
  def jump_move(start_pos, range, multiplier)
    move_block = []
    range.each_with_index do |dir_arr, index|
      move_block << start_pos.map.with_index { |v, i| v += dir_arr.fetch(i) * multiplier }
    end
    move_block
  end

  sig  {params(start_pos: T::Array[Integer], range: T::Array[T::Array[Integer]]).returns(T::Array[T::Array[Integer]])}
  def pawn_move(start_pos, range)
    all_moves = T.let(jump_move(start_pos, range, 1).select { |arr| arr if (arr.all? { |val| (val >= 0 && val <= 7) }) }, T::Array[T::Array[Integer]])

    #Isolate and filter diagonal movements
    diagonal_moves = T.let(all_moves.select { |arr| arr.fetch(1) != start_pos.fetch(1) }, T::Array[T::Array[Integer]])
    all_moves = (all_moves - diagonal_moves)
    diagonal_moves.reject! { |arr| (empty_square?(arr) || friendly_fire?(start_pos, arr)) }

    # Remove two-step if pawn has been previously moved or if there is an enemy pawn in the path
    if !(@board.fetch(start_pos.fetch(0)).fetch(start_pos.fetch(1)).unmoved)
      if !all_moves.size == 1
        all_moves.pop()
      end
    else
      if !empty_square?(all_moves.last) || (empty_square?(all_moves.last) && !empty_square?(all_moves.first))
        all_moves.pop()
      end
    end

    #Add in diagonal attacks if applicable
    all_moves = (all_moves + diagonal_moves) unless diagonal_moves.empty?

    #Prevent default movement if position occupied
    all_moves.shift unless empty_square?(all_moves.first)

    return all_moves
  end

  sig  {params(start_pos: T::Array[Integer], all_moves: T::Array[T::Array[Integer]]).returns(T::Array[T::Array[Integer]])}
  def valid_moves(start_pos, all_moves)
    all_moves.select { |arr| arr if ((arr.all? { |val| (val >= 0 && val <= 7) }) && arr.length == 2) } #within board
      .select { |arr| !friendly_fire?(start_pos, arr) } #is friendly_fire?
      .reject { |arr| arr.empty? }
  end

  sig {params(position: T.nilable(T::Array[Integer])).returns(T::Boolean)}
  def empty_square?(position)
    return false if position.nil?
    position.select! { |val| (val >= 0 && val < 8) }
    if position.length == 2
      return true if (@board.fetch(position.fetch(0)).fetch(position.fetch(1)).class == NilPiece)
    end
    return false
  end

  sig {params(start_pos: T::Array[Integer], end_pos: T::Array[Integer]).returns(T::Boolean)}
  def friendly_fire?(start_pos, end_pos)
    @board.fetch(start_pos.fetch(0)).fetch(start_pos.fetch(1)).color == @board.fetch(end_pos.fetch(0)).fetch(end_pos.fetch(1)).color
  end

  sig {params(start_pos: T::Array[Integer], end_pos: T::Array[Integer], color: String).returns(T::Boolean)}
  def can_move?(start_pos, end_pos, color)
    piece = @board.fetch(start_pos.fetch(0)).fetch(start_pos.fetch(1))
    return false if piece.class == NilPiece
    return false if piece.color != color
    possible_moves(start_pos).any? { |arr| arr == end_pos }
  end

  sig {params(start_pos: T::Array[Integer], end_pos: T::Array[Integer], color: String).void}
  def move(start_pos, end_pos, color)
    piece = @board.fetch(start_pos.fetch(0)).fetch(start_pos.fetch(1))

    # Capture piece
    @captured_piece = @board.fetch(end_pos.fetch(0)).fetch(end_pos.fetch(1))

    #Move to final position
    T.must(@board[T.must(end_pos[0])])[T.must(end_pos[1])] = piece
    T.must(@board[T.must(start_pos[0])])[T.must(start_pos[1])] = NilPiece.new("")

    piece.unmoved = false
  end

  sig {void}
  def initialize_moves
    (0..7).each do |row|
      (0..7).each do |col|
        unless T.must(@board[row])[col].class == NilPiece
          possible_moves([row,col])
        end
      end
    end
  end
end
