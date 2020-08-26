# typed: true
require "sorbet-runtime"

module Display
  include Kernel
  extend T::Sig

  RANKS = T.let(("1".."8").to_a, T::Array[String])
  FILES = T.let(("A".."H").to_a, T::Array[String])
  PAWNS = T.let([1, 6], T::Array[Integer])
  ROOKS = T.let([0, 7], T::Array[Integer])
  KNIGHTS = T.let([1, 6], T::Array[Integer])
  BISHOPS = T.let([2, 5], T::Array[Integer])
  QUEENS = T.let([3], T::Array[Integer])
  KINGS = T.let([4], T::Array[Integer])

  sig {void}
  def setup_board()
    PAWNS.each do |val|
      @board[val].map! { |square| square = Pawn.new(is_first?(val, PAWNS)) }
    end

    ROOKS.each do |row|
      color = is_first?(row, ROOKS)
      ROOKS.each { |val| @board[row][val] = Rook.new(color) }
      KNIGHTS.each { |val| @board[row][val] = Knight.new(color) }
      BISHOPS.each { |val| @board[row][val] = Bishop.new(color) }
      QUEENS.each { |val| @board[row][val] = Queen.new(color) }
      KINGS.each { |val| @board[row][val] = King.new(color) }
    end
  end

  sig {params(val: Integer, arr: T::Array[Integer]).returns(String)}
  def is_first?(val, arr)
    (val == arr.first) ? "white" : "black"
  end

  sig {void}
  def display_board()
    print "\t"
    print FILES.join("\t")
    print ("\n\n")
    puts
    @board.to_enum.with_index.reverse_each do |row, i|
      print RANKS[i]
      print "\t"
      row.each { |square| print "%s\t" % [square.icon] }
      print "\n\n"
      puts
    end
  end
end
