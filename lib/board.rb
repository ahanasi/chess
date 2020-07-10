require "pry"
class Board
  attr_accessor :board
  RANKS = ("1".."8").to_a
  FILES = ("A".."H").to_a

  def initialize
    @board = Array.new(8, ".").map { |row| Array.new(8, ".") }
  end

  def display_board()
    print "\t"
    print FILES.join("\t")
    print ("\n")
    puts
    @board.to_enum.with_index.reverse_each do |row, i|
      print RANKS[i]
      print "\t"
      print row.join("\t")
      print "\n\n"
      puts
    end
  end
end

binding.pry
