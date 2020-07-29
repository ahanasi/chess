require_relative "board.rb"
require "pry"

class Game
  attr_accessor :board, :is_white, :capture, :current_move, :current_piece

  def initialize
    @board = Board.new()
    @is_white = true
    @capture = Hash.new { |hsh, key| hsh[key] = [] }
    @current_move = []
    @current_piece = NilPiece.new("")
  end

  def self.driver
    system "clear"
    puts "Welcome to Chess! Press 'S' to start a new game. Press enter to exit."
    gets.chomp.upcase == "S" ? Game.new().play_game : exit
  end

  def play_game
    count = 0
    until count > 10
      play_round()
      count += 1
    end
  end

  def play_round
    system "clear"
    @board.display_board
    if @is_white
      puts "White's move"
      puts "Captured Pieces: ".concat(
        @capture[:white].reduce(" ") do |k, piece|
          k + " " + piece.icon
        end
      )
    else
      puts "Black's move"
      puts "Captured Pieces: ".concat(
        @capture[:black].reduce("") do |k, piece|
          k + " " + piece.icon
        end
      )
    end
    puts "(Ex: Type in A3 B4 to move the piece at A3 to B4)"

    #Get valid move from user

    loop do
      @current_move = get_position()
      @current_piece = @board.board[@current_move[0][0]][@current_move[0][1]]

      #Check for en_passant
      if @current_piece.class == Pawn && @current_piece.cant_ep == false && ep_pawn()
        result = en_passant()
        break if result
      end

      captured_piece = @board.move(@current_move[0], @current_move[1], turn_color)

      if captured_piece
        capture(captured_piece)
        break
      end
      @current_move = []
      puts "Please enter a valid move"
    end

    @is_white = !@is_white
  end

  def turn_color
    return @is_white ? "white" : "black"
  end

  def capture(captured_piece)
    unless captured_piece.class == NilPiece
      @is_white ? @capture[:white].push(captured_piece) : @capture[:black].push(captured_piece)
    end
  end

  def en_passant()
    temp = ep_pawn()
    @current_piece.cant_ep = true
    if temp[0] == get_piece([@current_move[0][0], @current_move[1][1]])
      capture(temp[0])
      @board.board[current_move[1][0]][current_move[1][1]] = @current_piece
      @board.board[current_move[0][0]][current_move[0][1]] = NilPiece.new("")
      @board.board[current_move[0][0]][current_move[1][1]] = NilPiece.new("")
      return true
    end
    return false
  end

  def ep_pawn()
    start_pos = @current_move[0]
    if (start_pos[0] == 3 && turn_color == "black") || (start_pos[0] == 4 && turn_color == "white")
      #Get en_passant pawns
      pawn = @board
        .jump_move(start_pos, [[0, 1], [0, -1]], 1)
        .select { |arr| arr if ((arr.all? { |val| (val >= 0 && val < 8) })) }
        .map { |arr| get_piece(arr) }
        .select { |piece| piece if (piece.class == Pawn && piece.color != turn_color) }
    end
    return pawn unless pawn.nil?
    return false
  end

  def to_coord(str)
    result = str.split("")
    result[0] = result[0].ord - 65
    result[1] = result[1].to_i - 1
    return result
  end

  def get_position()
    position_arr = []
    coord = gets.chomp.upcase
    start_pos, end_pos = coord.split(" ")
    return position_arr = [to_coord(start_pos).reverse(), to_coord(end_pos).reverse()]
  end

  def get_piece(position)
    return @board.board[position[0]][position[1]]
  end

  def check
  end

  def checkmate
  end

  def stalemate
  end
end

Game.driver()
