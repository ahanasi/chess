require_relative "board.rb"
require "pry"

class Game
  attr_accessor :board, :is_white, :player_1, :player_2

  def initialize
    @board = Board.new()
    @is_white = true
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
    else
      puts "Black's move"
    end
    puts "(Ex: A3 B4 moves the piece at A3 to B4)"

    #Get valid move from user
    loop do
      position = get_position()
      break if @board.move(position[0], position[1], turn_color)
      position = []
      puts "Please enter a valid move"
    end

    @is_white = !@is_white
    
  end

  def turn_color
    return @is_white ? "white" : "black"
  end

  def en_passant
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

  def check
  end

  def checkmate
  end

  def stalemate
  end
end

Game.driver()
