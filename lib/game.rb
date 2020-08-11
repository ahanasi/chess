require_relative "board.rb"
require "pry"

class Array
  def coordinates(element)
    each_with_index do |subarray, i|
      j = subarray.index(element)
      return i, j if j
    end
    nil
  end
end

class Game
  attr_accessor :board, :turn, :capture, :current_move, :current_piece, :current_set, :previous_set, :checked_king

  def initialize
    @board = Board.new()
    @turn = 0
    @capture = Hash.new { |hsh, key| hsh[key] = [] }
    @current_move = []
    @current_piece = NilPiece.new("")
    @current_set = []
    @previous_set = []
    @checked_king = false
  end

  def self.driver
    system "clear"
    puts "Welcome to Chess! Press 'S' to start a new game. Press enter to exit."
    gets.chomp.upcase == "S" ? Game.new().play_game : exit
  end

  def play_game
    count = 0
    @board.initialize_moves()
    until count > 30
      play_round()
      count += 1
    end
  end

  def play_round
    system "clear"
    @board.display_board

    #Get current_set
    @current_set = curr_set().flatten(1)

    if @turn % 2 == 0
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

      #Is the king in check?
      if @checked_king
        #Check for checkmate
        if !move_king_after_check && !capture_checking_piece
          if !block_checking_piece
            puts "You have been checkmated!"
            return
          end
        end
        puts "You are in check!"
        check_loop()
        @checked_king = false
      else
        @current_move = get_position()
        @current_piece = get_piece(@current_move[0])
      end

      #Check for en_passant
      if @current_piece.class == Pawn && @current_piece.cant_ep == false && ep_pawn()
        @current_piece.cant_ep = true
        result = en_passant()
        break if result
      end

      #If current piece is king, check for valid move
      if @current_piece.class == King
        loop do
          temp = @board.move(@current_move[0], @current_move[1], turn_color())
          if temp
            update_moves(@previous_set)
            if @previous_set.any? { |piece| piece.moves.include?(@current_move[1]) }
              @board.board[@current_move[0][0]][@current_move[0][1]] = @current_piece
              @board.board[@current_move[1][0]][@current_move[1][1]] = temp

              puts "Please enter a valid move"
              @current_move = get_position()
              @current_piece = get_piece(@current_move[0])
              if @current_piece.class != King
                break
              end
            else
              @board.board[@current_move[0][0]][@current_move[0][1]] = @current_piece
              @board.board[@current_move[1][0]][@current_move[1][1]] = temp
              break
            end
          end
        end
      end

      captured_piece = @board.move(@current_move[0], @current_move[1], turn_color)

      if captured_piece
        capture(captured_piece)
        break
      end
      @current_move = []
      puts "Please enter a valid move"
    end

    #If current piece is a pawn, check for promotion
    if @current_piece.class == Pawn && promotion()
      @board.board[@current_move[1][0]][@current_move[1][1]] = promotion()
      @current_set = curr_set().flatten(1)
    end

    #Update moves for current set
    update_moves(@current_set)
    @previous_set = @current_set

    #Check for CHECK
    @checked_king = check(@current_set) if check(@current_set)

    @turn += 1
  end

  def turn_color
    return @turn % 2 == 0 ? "white" : "black"
  end

  def capture(captured_piece)
    unless captured_piece.class == NilPiece
      (@turn % 2 == 0) ? @capture[:white].push(captured_piece) : @capture[:black].push(captured_piece)
    end
  end

  def en_passant()
    temp = ep_pawn()
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

  def promotion
    end_pos = @current_move[1]
    if (end_pos[0] == 0 && turn_color == "black") || (end_pos[0] == 7 && turn_color == "white")
      puts "Promote your pawn to a Queen (Q), Knight (K) , Rook (R) or Bishop (B)."
      puts "Type in Q, K, R, or B. "
      promoted_piece = gets.chomp.upcase
      until promoted_piece.match(/^[qQkKrRbB]$/)
        puts "Type in Q, K, R, or B. "
        promoted_piece = gets.chomp.upcase
      end

      case promoted_piece
      when "Q"
        promoted_piece = Queen.new(turn_color)
      when "K"
        promoted_piece = Knight.new(turn_color)
      when "R"
        promoted_piece = Rook.new(turn_color)
      when "B"
        promoted_piece = Bishop.new(turn_color)
      else
        promoted_piece = false
      end
      return promoted_piece
    end
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

  def check(set)
    # all_moves = @board.possible_moves(@current_move[1])
    # return king_pos = all_moves.select { |square| get_piece(square).class == King }
    king_pos = []
    set.each do |piece|
      piece.moves.each do |pos|
        if get_piece(pos).class == King && get_piece(pos).color != piece.color
          return king_pos = pos
        end
      end
    end
    return false
  end

  def curr_set
    @board.board.map do |row|
      row.reject { |piece| piece.class == NilPiece || piece.color != turn_color || @capture.values.include?(piece) }
    end
  end

  def update_moves(chess_set)
    chess_set.each do |piece|
      unless @board.board.coordinates(piece).nil?
        @board.possible_moves(@board.board.coordinates(piece))
      end
      if piece.class == Pawn && piece.moves.size > 1
        piece.moves.reject! { |move| move[1] == @board.board.coordinates(piece)[1] }
      end
    end
  end

  def stalemate
  end

  def check_loop
    until find_checking_pieces().empty?
      @current_move = get_position()
      @current_piece = get_piece(@current_move[0])

      temp = @board.move(@current_move[0], @current_move[1], turn_color)
      if temp
        update_moves(@previous_set)
        if @previous_set.any? { |piece| piece.moves.include?(@current_move[1]) }
          @board.board[@current_move[0][0]][@current_move[0][1]] = @current_piece
          @board.board[@current_move[1][0]][@current_move[1][1]] = temp
          @current_piece = []
        else
          @board.board[@current_move[0][0]][@current_move[0][1]] = @current_piece
          @board.board[@current_move[1][0]][@current_move[1][1]] = temp
          break
        end
      end
      puts "Please make a valid move"
    end
  end

  def move_king_after_check
    # Find all possible moves for checked king
    king_pos = @checked_king
    king = get_piece(king_pos)
    king_moves = @board.possible_moves(king_pos)
    return false if king_moves.empty?

    result_arr = []

    #For each move, temporarily move king to the possible move location
    king_moves.each do |pos|
      temp = @board.move(king_pos, pos, turn_color())

      #Update previous set moves
      update_moves(@previous_set)

      #Check if king is in check and append result to array
      result_arr << check(@previous_set)
      #Return pieces to original position
      @board.board[king_pos[0]][king_pos[1]] = king
      @board.board[pos[0]][pos[1]] = temp
      update_moves(@previous_set)
    end

    # Return false if all possible moves keep him in check
    return false if result_arr.none? { |val| val == false }
    return true
  end

  def capture_checking_piece
    #Find out location of all pieces that could put the king in check
    enemy_pos = find_checking_pieces()

    #Check if any checking pieces can be captured by the current set
    return enemy_pos.any? { |arr| @current_set.any? { |piece| piece.moves.include?(arr) } }
  end

  def block_checking_piece
    enemy_pos = find_checking_pieces()
    rooks = enemy_pos.select { |pos| get_piece(pos).class == Rook }
    bishops = enemy_pos.select { |pos| get_piece(pos).class == Bishop }
    queen = enemy_pos.select { |pos| get_piece(pos).class == Queen }

    return false if (rooks.size > 1)
    return false if (bishops.size > 1)
    return false if ((rooks.size == 1 || bishops.size == 1) && queen.size == 1)
    return false if (rooks.size == 1 && bishops.size == 1)

    result = []

    if rooks
      rooks.each do |rook|
        rook_moves = @board.possible_moves(rook)
        rook_moves = rook_moves - @checked_king

        rook_moves = rook_moves.select { |move| (move[0] == @checked_king[0]) || (move[1] == @checked_king[1]) }
        result = rook_moves.any? { |arr| @current_set.any? { |piece| piece.moves.include?(arr) } }
      end
      return true if result
    end

    if bishops
      bishops.each do |bishop|
        bishop_moves = @board.possible_moves(bishop)
        bishop_moves = bishop_moves - @checked_king

        #Find bishop moves in applicable quadrant
        if @checked_king[0] > bishop[0]
          if @checked_king[1] > bishop[1]
            #First Quadrant
            bishop_moves.select! { |move| (move[0] > bishop[0]) && move[1] > bishop[1] }
          else
            #Second Quadrant
            bishop_moves.select! { |move| (move[0] > bishop[0]) && move[1] < bishop[1] }
          end
        else
          if @checked_king[1] < bishop[1]
            #Third Quadrant
            bishop_moves.select! { |move| (move[0] < bishop[0]) && move[1] < bishop[1] }
          else
            #Fourth Quadrant
            binding.pry
            bishop_moves.select! { |move| (move[0] > bishop[0]) && move[1] < bishop[1] }
          end
        end

        binding.pry
        result = bishop_moves.any? { |arr| @current_set.any? { |piece| piece.moves.include?(arr) } }
      end
      return true if result
    end

    if queen
      queen_moves = @board.possible_moves(queen)
      queen_moves = queen_moves - @checked_king

      if valid_moves = queen_moves.select { |move| move[0] == @checked_king[0] }
        result = valid_moves.any? { |arr| @current_set.any? { |piece| piece.moves.include?(arr) } }
      elsif valid_moves = queen_moves.select { |move| move[1] == @checked_king[1] }
        result = valid_moves.any? { |arr| @current_set.any? { |piece| piece.moves.include?(arr) } }
      else
        if @checked_king[0] > queen[0]
          if @checked_king[1] > queen[1]
            #First Quadrant
            queen_moves.select! { |move| (move[0] > queen[0]) && move[1] > queen[1] }
          else
            #Second Quadrant
            queen_moves.select! { |move| (move[0] > queen[0]) && move[1] < queen[1] }
          end
        else
          if @checked_king[1] < queen[1]
            #Third Quadrant
            queen_moves.select! { |move| (move[0] < queen[0]) && move[1] < queen[1] }
          else
            #Fourth Quadrant
            queen_moves.select! { |move| (move[0] > queen[0]) && move[1] < queen[1] }
          end
        end
        result = queen_moves.any? { |arr| @current_set.any? { |piece| piece.moves.include?(arr) } }
      end
      return true if result
    end

    return false
  end

  def find_checking_pieces
    enemy_pos = []
    @previous_set.each do |piece|
      piece.moves.each do |pos|
        if get_piece(pos).class == King && get_piece(pos).color != piece.color
          enemy_pos << @board.board.coordinates(piece)
        end
      end
    end
    return enemy_pos
  end
end
