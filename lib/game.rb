# typed: true
require "sorbet-runtime"
require_relative "board.rb"

class Array
  include Kernel
  extend T::Sig

  sig { params(element: Piece).returns(T.nilable(T::Array[Integer])) }

  def coordinates(element)
    each_with_index do |subarray, i|
      j = subarray.index(element)
      return i, j if j
    end
    return nil
  end
end

class Game
  include Kernel
  extend T::Sig

  attr_accessor :board, :turn, :capture, :current_move, :current_piece, :current_set, :previous_set, :king_checked, :checked_king_pos, :castle_positions, :promoted_piece
  
  sig { void }
  def initialize
    @board = T.let(Board.new(), Board)
    @turn = T.let(0, Integer)
    @capture = T.let(Hash.new { |hsh, key| hsh[key] = [] }, T::Hash[Symbol, T::Array[Piece]])
    @current_move = T.let([], T::Array[T::Array[Integer]])
    @current_piece = T.let(NilPiece.new(""), Piece)
    @current_set = T.let([], T::Array[Piece])
    @previous_set = T.let([], T::Array[Piece])
    @king_checked = T.let(false, T::Boolean)
    @checked_king_pos = T.let([], T::Array[Integer])
    @castle_positions = T.let([], T::Array[T::Array[Integer]])
    @promoted_piece = T.let(NilPiece.new(""), Piece)
  end

  sig { void }
  def self.driver
    system "clear"
    puts "Welcome to Chess! Press 'S' to start a new game. Press enter to exit."
    gets.chomp.upcase == "S" ? Game.new().play_game : exit
  end

  sig { void }
  def play_game
    @board.initialize_moves()
    count = 0
    until count < 0
      count = play_round()
    end
    puts "The game has ended"
  end

  sig { returns(Integer) }
  def play_round
    system "clear"
    @board.display_board

    #Get current_set
    @current_set = curr_set().flatten(1)

    #Turn message
    turn_message()
    puts "(Ex: Type in A3 B4 to move the piece at A3 to B4)"
    puts "Type in 'C' to Castle"

    #Get valid move from user

    legal_move = 0
    while legal_move == 0
      puts "BEFORE GET_LEGAL_MOVE"
      legal_move = get_legal_move()
      if legal_move == -1
        return -1
      end
    end

    #If current piece is a pawn, check for promotion
    if @current_piece.class == Pawn
      if promotion()
        @board.board[T.must(T.must(@current_move[1])[0])][T.must(T.must(@current_move[1])[1])] = @promoted_piece
        @current_set = curr_set().flatten(1)
      end
    end

    #Assign current_set to previous_set and update moves
    @previous_set = @current_set
    update_moves(@previous_set)

    #Check for CHECK
    @king_checked = true if check()

    @turn += 1
  end

  # -1 -> end the game
  #  0 -> invalid move (ask again for a new move)
  #  1 -> valid move (proceed with the round)
  sig { returns(Integer) }
  def get_legal_move
    puts "IN GET LEGAL MOVE"
    #Is the king in check?
    if @king_checked
      #Check for checkmate
      if stalemate()
        puts "You have been checkmated!"
        return -1
      end
      puts "You are in check!"
      check_loop()
      return 1
    elsif stalemate() && @current_set.all? { |piece| piece.moves.empty? }
      puts "Stalemate! The game is a draw"
      return -1
    else
      did_castle = castle_or_move()
      if did_castle
        puts "CASTLED"
        return 1
      else
        # User is moving, not castling
        puts "DID NOT CASTLE"

        # Handle en-passant
        if @current_piece.class == Pawn && !T.cast(@current_piece, Pawn).cant_ep && is_trying_to_ep()
          definitely_pawn = T.cast(@current_piece, Pawn)
          puts "TRYING TO ENPASSANT"
          if en_passant()
            definitely_pawn.cant_ep = true
            puts "SUCCESSFUL IN EP"
            return 1
          else
            puts "COULD NOT EP - RETRY"
            return 0
          end
        end

        #Check for legal move
        if @board.can_move?(T.must(@current_move[0]), T.must(@current_move[1]), turn_color())  
          if moving_to_check?()
            puts "That move puts your king in check. Please move another piece."
            puts "KING IN CHECK"
            return 0
          else
            return 1
          end               
        end
        puts "MOVE IS NOT POSSIBLE"
        return 0        
      end
    end
    
    @current_move = []
    return 0 
  end


  sig {params(piece: Piece,curr_pos: T::Array[Integer], end_pos: T::Array[Integer]).returns(T::Boolean)}
  def temp_move(piece,curr_pos,end_pos)
    move_state = piece.unmoved
    @board.move(curr_pos, end_pos, turn_color())
    @previous_set.reject! { |piece| piece == get_piece(end_pos) }
    update_moves(@previous_set)
    return move_state
  end

  sig {params(piece: Piece, move_status: T::Boolean, start_pos: T::Array[Integer], end_pos: T::Array[Integer]).void}
  def undo_temp_move(piece,move_status,start_pos,end_pos)
    @board.board[start_pos[0]][start_pos[1]] = piece
    @board.board[end_pos[0]][end_pos[1]] = @board.captured_piece
    piece.unmoved = move_status
    @previous_set << @board.captured_piece unless @board.captured_piece.class == NilPiece
    update_moves(@previous_set)
  end

  # true -> Move puts the king in check
  # false -> Move does not put the king in check
  sig {returns(T::Boolean)}
  def moving_to_check?()
                
    #CHECK TO MAKE SURE THE MOVE DOES NOT PUT KING IN CHECK
    puts "CHECK TO MAKE SURE THE MOVE DOES NOT PUT KING IN CHECK"
  
    #Temporarily move pieces
    move_state = temp_move(@current_piece,T.must(@current_move[0]), T.must(@current_move[1]))
  
    if (!find_checking_pieces().empty?)
      #Undo temp move
      undo_temp_move(@current_piece,move_state,T.must(@current_move[0]),T.must(@current_move[1]))
      puts "That move puts your king in check. Please move another piece."
      puts "KING IN CHECK"
      return true
    end
    # Put captured piece in capture hash
    capture_piece(@board.captured_piece)
    return false
  end

  sig { returns(String) }
  def turn_color
    return @turn % 2 == 0 ? "white" : "black"
  end

  sig { params(captured_piece: Piece).void }
  def capture_piece(captured_piece)
    unless captured_piece.class == NilPiece
      (@turn % 2 == 0) ? T.must(@capture[:white]).push(captured_piece) : T.must(@capture[:black]).push(captured_piece)
    end
  end

  # true -> en-passant has been successfully performed
  # false -> en-passant has not been performed
  sig { returns(T::Boolean) }
  def en_passant()
    if ep_pawn() && is_trying_to_ep()
      capture_piece(get_piece([T.must(T.must(@current_move[0])[0]), T.must(T.must(@current_move[1])[1])]))
      @board.board[T.must(T.must(@current_move[1])[0])][T.must(T.must(@current_move[1])[1])] = @current_piece
      @board.board[T.must(T.must(@current_move[0])[0])][T.must(T.must(@current_move[0])[1])] = NilPiece.new("")
      @board.board[T.must(T.must(@current_move[0])[0])][T.must(T.must(@current_move[1])[1])] = NilPiece.new("")
      return true
    end
    return false
  end

  # true -> user is trying to en-passant
  # false -> user is not trying to en-passant
  sig {returns(T::Boolean)}
  def is_trying_to_ep
    
    start_pos = @current_move[0]
    end_pos = @current_move[1]

    end_pos_col_right = T.must(T.must(end_pos)[1]) > T.must(T.must(start_pos)[1])
    end_pos_col_left = T.must(T.must(end_pos)[1]) < T.must(T.must(start_pos)[1])
    
    #Pawns must be on their fifth rank
    if (T.must(start_pos)[0] == 3 && turn_color == "black") || (T.must(start_pos)[0] == 4 && turn_color == "white")
      #Pawn is trying to diagonally move to an empty square
      if ((end_pos_col_right) || (end_pos_col_left)) && (get_piece(T.must(end_pos)).class == NilPiece)
        return true
      end
    end
    return false
  end

  # true -> enemy pawn can be captured by en-passant
  # false -> no enemy pawns can be captured by en-passant
  sig { returns(T::Boolean) }
  def ep_pawn()
    start_pos = @current_move[0]
    if (T.must(start_pos)[0] == 3 && turn_color == "black") || (T.must(start_pos)[0] == 4 && turn_color == "white")
      #Get en_passant pawns
      pawn = @board
        .jump_move(T.must(start_pos), [[0, 1], [0, -1]], 1)
        .select { |arr| arr if ((arr.all? { |val| (val >= 0 && val < 8) })) }
        .map { |arr| get_piece(arr) }
        .select { |piece| piece if (piece.class == Pawn && piece.color != turn_color) }
    end
    return true unless pawn.nil?
    return false
  end

  sig { returns(T::Boolean) }
  def promotion
    end_pos = @current_move[1]
    if (T.must(end_pos)[0] == 0 && turn_color == "black") || (T.must(end_pos)[0] == 7 && turn_color == "white")
      puts "Promote your pawn to a Queen (Q), Knight (K) , Rook (R) or Bishop (B)."
      puts "Type in Q, K, R, or B. "
      promo = gets.chomp.upcase
      until promo.match(/^[qQkKrRbB]$/)
        puts "Type in Q, K, R, or B. "
        promo = gets.chomp.upcase
      end

      case promo
      when "Q"
        promo = Queen.new(turn_color)
      when "K"
        promo = Knight.new(turn_color)
      when "R"
        promo = Rook.new(turn_color)
      when "B"
        promo = Bishop.new(turn_color)
      else
        return false
      end
      @promoted_piece = promo
      return true
    end
    return false
  end

  sig { params(str: String).returns(T::Array[Integer]) }
  def to_coord(str)
    result = str.split("")
    result[0] = T.must(result[0]).ord - 65
    result[1] = result[1].to_i - 1
    return result.map(&:to_i)
  end

  sig {returns(String)}
  def get_user_input
    user_input = gets.chomp.upcase
    #Guard against garbage
    until user_input.match(/^[a-zA-Z][1-8] [a-zA-Z][1-8]$/) || (user_input.match(/^[cC]$/) && (can_castle?()))
      puts "Please move another piece."
      user_input = gets.chomp.upcase
    end
    return user_input
  end

  # true  -> castled
  # false -> moved
  sig {returns(T::Boolean)}
  def castle_or_move
    user_input = get_user_input()
    if user_input == "C"
      castle()
      return true
    else
      @current_move = get_position(user_input)
      @current_piece = get_piece(T.must(@current_move[0]))
      return false
    end
  end

  sig { params(coord: String).returns(T::Array[T::Array[Integer]]) }
  def get_position(coord)
    position_arr = []
    start_pos, end_pos = coord.split(" ")
    return position_arr = [to_coord(T.must(start_pos)).reverse(), to_coord(T.must(end_pos)).reverse()]
  end

  sig { params(position: T::Array[Integer]).returns(Piece) }
  def get_piece(position)
    return @board.board[position[0]][position[1]]
  end

  sig { returns(T::Boolean) }
  def check()
    set = @previous_set
    @checked_king_pos = []
    set.each do |piece|
      piece.moves.each do |pos|
        if get_piece(pos).class == King && get_piece(pos).color != piece.color 
          @checked_king_pos = pos
          return true
        end
      end
    end
    return false
  end

  sig { returns(T::Array[Piece]) }
  def curr_set
    @board.board.map do |row|
      row.reject { |piece| piece.class == NilPiece || piece.color != turn_color || @capture.values.include?(piece) }
    end
  end

  sig { params(chess_set: T::Array[Piece]).void }
  def update_moves(chess_set)
    chess_set.each do |piece|
      my_coord = @board.board.coordinates(piece)

      unless my_coord.nil?
        @board.possible_moves(@board.board.coordinates(piece))
      end

      if piece.class == Pawn && !my_coord.nil?
        piece.moves.reject! do |move|
          move[1] == my_coord[1]
        end
      end

    end
  end

  sig { params(chess_set: T::Array[Piece]).void }
  def update_moves_with_pawn(chess_set)
    chess_set.each do |piece|
      unless @board.board.coordinates(piece).nil?
        @board.possible_moves(@board.board.coordinates(piece))
      end
    end
  end

  sig { returns(T::Boolean) }
  def stalemate
    puts "CAN MOVE KING: #{can_move_king}, CAPTURE_CHECKING_PIECE: #{capture_checking_piece}, BLOCK: #{block_checking_piece}"
    return !can_move_king && !capture_checking_piece && !block_checking_piece
  end

  sig {void}
  def check_loop

    while @king_checked
      puts "IN CHECK LOOP"
      user_input = get_user_input()
      @current_move = get_position(user_input)
      @current_piece = get_piece(T.must(@current_move[0]))

      if @board.can_move?(T.must(@current_move[0]), T.must(@current_move[1]), turn_color())
        if moving_to_check?()
          puts "Please make a valid move 1"
        else
          @king_checked = false
          break
        end
      else
        puts "Please make a valid move 2"
      end
    end
  end

  sig { returns(T::Boolean) }
  def can_move_king

    # Find all possible moves for king
    king = @current_set.select { |piece| piece.class == King }[0]

    king_pos = @board.board.coordinates(king)
    king_moves = @board.possible_moves(king_pos)

    return false if king_moves.empty?

    result_arr = []

    #For each move, temporarily move king to the possible move location
    king_moves.each do |position|

      #Temp move
      move_state = temp_move(T.must(king),king_pos,position)

      #Check if king is in check and append result to array

      if check()
        result_arr << false
      else
        result_arr << true
      end

      #Return pieces to original position
      undo_temp_move(T.must(king),move_state,king_pos,position)
    end

    # Return false if all possible moves keep him in check
    return false if result_arr.none? { |val| val }
    return true
  end

  sig { returns(T::Boolean) }
  def capture_checking_piece

    #Find out location of all pieces that could put the king in check
    enemy_pos = find_checking_pieces()
    result_arr = []
  
    #Check if any checking pieces can be captured by the current set
     enemy_pos.each do |arr|
      @current_set.each do |piece|
        if piece.moves.include?(arr)
          
          checking_piece = get_piece(arr)
          curr_piece_pos = @board.board.coordinates(piece)
          
          #Temporarily move piece
          move_state = temp_move(piece,curr_piece_pos,arr)
  
          if !(find_checking_pieces().empty?)
            #KING IN  CHECK
            result_arr << false
          else
            result_arr << true
          end
  
          #Return pieces to original position
          undo_temp_move(piece,move_state,curr_piece_pos,arr)
        else
          result_arr << false
        end
      end
    end
    
    
    # Return false if none of the possible moves can capture checking piece
    puts "RESULT ARRAY: #{result_arr}"
    return false if result_arr.none? { |val| val }
    return true
  end

  sig { returns(T::Boolean) }
  def block_checking_piece
    
    update_moves_with_pawn(@current_set)
    enemy_pos = find_checking_pieces()
    
    result_arr = T.let([false],T::Array[T::Boolean])
    result = T.let(false, T::Boolean)


    rooks = enemy_pos.select { |pos| get_piece(pos).class == Rook }
    bishops = enemy_pos.select { |pos| get_piece(pos).class == Bishop }
    queen = enemy_pos.select { |pos| get_piece(pos).class == Queen }.first

    king_pos = @board.board.coordinates(@current_set.select{|piece| piece.class == King}[0])

    return false if (rooks.size > 1) || (bishops.size > 1)
    return false if ((rooks.size == 1 || bishops.size == 1) && !queen.nil?)
    return false if (rooks.size == 1 && bishops.size == 1)

    if !rooks.empty?
      rooks.each do |rook|
        rook_moves = @board.possible_moves(rook)
        rook_moves = rook_moves - king_pos

        rook_moves = rook_moves.select { |move| (move[0] == king_pos[0]) || (move[1] == king_pos[1]) }

        rook_moves.each do |arr|
          @current_set.each do |piece|
            if piece.moves.include?(arr)
        
              checking_piece_pos = rook
              checking_piece = get_piece(rook)
        
              curr_piece_pos = @board.board.coordinates(piece)

              #Temporarily move piece
              move_state = temp_move(piece,curr_piece_pos,arr)
        
              if !(find_checking_pieces().empty?)
                #KING IS IN CHECK
                result_arr << false
              else
                #KING NOT IN CHECK
                result_arr << true
              end

              #Undo Move
              undo_temp_move(piece,move_state,curr_piece_pos,arr)
            else
              result_arr << false
            end
          end
        end
        result = result_arr.any? {|val| val}        
      end
    end

    if !bishops.empty?
      bishops.each do |bishop|

        bishop_moves = @board.possible_moves(bishop)
        bishop_moves = bishop_moves - king_pos

        #Find bishop moves in applicable quadrant
        if king_pos[0] > T.must(bishop[0])
          if king_pos[1] > T.must(bishop[1])
            #First Quadrant
            bishop_moves.select! { |move| (T.must(move[0]) > T.must(bishop[0])) && (T.must(move[1]) > T.must(bishop[1])) }
          else
            #Second Quadrant
            bishop_moves.select! { |move| (T.must(move[0]) > T.must(bishop[0])) && (T.must(move[1]) < T.must(bishop[1])) }
          end
        else
          if king_pos[1] < T.must(bishop[1])
            #Third Quadrant
            bishop_moves.select! { |move| (T.must(move[0]) < T.must(bishop[0])) && (T.must(move[1]) < T.must(bishop[1])) }
          else
            #Fourth Quadrant
            bishop_moves.select! { |move| (T.must(move[0]) > T.must(bishop[0])) && (T.must(move[1]) < T.must(bishop[1])) }
          end
        end

        bishop_moves.each do |arr|
          @current_set.each do |piece|
            if piece.moves.include?(arr)

              checking_piece_pos = bishop
              checking_piece = get_piece(bishop)

              curr_piece_pos = @board.board.coordinates(piece)
              
              #Temporarily move piece
              move_state = temp_move(piece,curr_piece_pos,arr)

              if !(find_checking_pieces().empty?)
                result_arr << true
              else
                result_arr << false
              end

              #Undo Move
              undo_temp_move(piece,move_state,curr_piece_pos,arr)
            else
              result_arr << false
            end
          end
        end

        result = result_arr.any? {|val| val}
      end
    end

    if !queen.nil?

      queen_moves = @board.possible_moves(queen)
      queen_moves.reject!{|pos| pos == king_pos}

      puts "KING POS: #{king_pos}"

      same_row = queen_moves.select { |move| (move[0] == king_pos[0]) && (move[0] == queen[0])  }
      same_col = queen_moves.select { |move| (move[1] == king_pos[1]) && (move[1] == queen[1]) }

      if !same_row.empty?
        result = same_row.any? { |arr| @current_set.any? { |piece| piece.moves.include?(arr) } }
      elsif !same_col.empty?
        result = same_col.any? { |arr| @current_set.any? { |piece| piece.moves.include?(arr) };}
        puts "RESULT FOR SAME COL: #{result}"
      else
        if king_pos[0] > queen[0]
          if king_pos[1] > queen[1]
            #First Quadrant
            queen_moves.select! { |move| (T.must(move[0]) > T.must(queen[0])) && (T.must(move[1]) > T.must(queen[1])) }
          else
            #Second Quadrant
            queen_moves.select! { |move| (T.must(move[0]) > T.must(queen[0])) && (T.must(move[1]) < T.must(queen[1])) }
          end
        else
          if king_pos[1] < queen[1]
            #Third Quadrant
            queen_moves.select! { |move| (T.must(move[0]) < T.must(queen[0])) && (T.must(move[1]) < T.must(queen[1])) }
          else
            #Fourth Quadrant
            queen_moves.select! { |move| (T.must(move[0]) > T.must(queen[0])) && (T.must(move[1]) < T.must(queen[1])) }
          end
        end

        
        queen_moves.each do |arr|
          @current_set.each do |piece|
            if piece.moves.include?(arr)
              
              checking_piece_pos = queen
              checking_piece = get_piece(queen)

              curr_piece_pos = @board.board.coordinates(piece)
              
              #Temporarily move piece
              move_state = temp_move(piece,curr_piece_pos,arr)

              if !(find_checking_pieces().empty?)
                #KING IS IN CHECK
                result_arr << false
              else
                #KING NOT IN CHECK
                result_arr << true
              end

              #Undo Move
              undo_temp_move(piece,move_state,curr_piece_pos,arr)
            else
              result_arr << false
            end
          end
        end
        result = result_arr.any? {|val| val}
      end
      update_moves(@current_set)
      return result
    end

    update_moves(@current_set)
    return result
  end

  sig { returns(T::Array[T::Array[Integer]]) }
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

  sig {void}
  def turn_message
    if @turn % 2 == 0
      puts "White's move"
      puts "Captured Pieces: ".concat(
        T.must(@capture[:white]).reduce(" ") do |k, piece|
          k + " " + piece.icon
        end
      )
    else
      puts "Black's move"
      puts "Captured Pieces: ".concat(
        T.must(@capture[:black]).reduce("") do |k, piece|
          k + " " + piece.icon
        end
      )
    end
  end

  sig {void}
  def castle()
    #Move King
    king = get_piece(T.must(@castle_positions[0]))
    @board.board[T.must(@castle_positions[0])[0]][T.must(@castle_positions[0])[1]] = NilPiece.new("")
    @board.board[T.must(@castle_positions[2])[0]][T.must(@castle_positions[2])[1]] = king

    #Move Rook
    rook = get_piece(T.must(@castle_positions[1]))
    @board.board[T.must(@castle_positions[1])[0]][T.must(@castle_positions[1])[1]] = NilPiece.new("")
    @board.board[T.must(@castle_positions[3])[0]][T.must(@castle_positions[3])[1]] = rook

    @current_piece = NilPiece.new("")
    @castle_positions = []
  end

  sig {returns(T::Boolean)}
  def can_castle?()

    #Check if king is in check or has moved
    king = @current_set.select { |piece| piece.class == King && piece.unmoved == true }[0]
    return false if (king.nil? || @king_checked)

    king_pos = (turn_color() == "white") ? [0, 4] : [7, 4]

    #Get valid rooks
    rooks = @current_set.select { |piece|
      piece.class == Rook &&
      piece.unmoved == true &&
      @board.board.coordinates(piece)[0] == king_pos[0]
    }
    return false if rooks.empty?

    #Check if both long and short castling are possible
    type = castling_user_input() if (rooks.length > 1)

    if type == "S"
      rook_pos = @board.board.coordinates(rooks[1])
    else
      rook_pos = @board.board.coordinates(rooks[0])
    end
    # rook_pos = @board.board.coordinates(rooks[1])

    #Get path between rook and king
    path = []
    if king_pos[1] > rook_pos[1]
      (1..2).each { |num| path << [king_pos[0], king_pos[1] - num - 1] }
    else
      (1..2).each { |num| path << [king_pos[0], king_pos[1] + num] }
    end

    #Return false if path is occupied
    return false unless path.all? { |position| get_piece(position).class == NilPiece }

    #Return false if enemy can move to any point on path
    @previous_set.each do |piece|
      piece.moves.each do |pos|
        if path.include?(pos)
          return false
        end
      end
    end

    @castle_positions = [king_pos, rook_pos, path[1], path[0]]
    return true
  end

  sig {returns(String)}
  def castling_user_input()
    puts "Long or short? (L/S)"
    castle_type = gets.chomp.upcase
    until castle_type.match(/^[lLsS]$/)
      puts "Type in L or S"
      castle_type = gets.chomp.upcase
    end
    return castle_type
  end
end

Game.driver()