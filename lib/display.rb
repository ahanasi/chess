module Display
  RANKS = ("1".."8").to_a
  FILES = ("A".."H").to_a
  PAWNS = [1, 6]
  ROOKS = [0, 7]
  KNIGHTS = [1, 6]
  BISHOPS = [2, 5]
  QUEENS = [3]
  KINGS = [4]

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

  def is_first?(val, arr)
    (val == arr.first) ? "white" : "black"
  end

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
