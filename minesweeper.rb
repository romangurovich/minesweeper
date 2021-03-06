require 'json'

class Board
  attr_reader :matrix
  #REV might be nice to have a comment on how your matrix stores all the state since its 3d
  #also, maybe better to not expose matrix like this, since it could be modified
  
  def initialize(matrix=nil)
    if matrix
      @matrix = matrix
    else
      #REV usually better to not have magic numbers, like the 9 here. perhaps you could use a constant
      @matrix = Array.new(9) { Array.new(9) { {b: false, display: "*"} } }
    end
    @lost, @win = false, false
  end

  def display_board
    @matrix.length.times do | x |
      @matrix[0].length.times do | y |
        print " #{@matrix[x][y][:display]} "
      end
      print "\n"
    end
    nil
  end

  def set_bombs
    bombs_coords.each do |coord|
      @matrix[coord[0]][coord[1]][:b] = true  #REV 3d array?
    end
  end

  def bombs_coords
    bomb_array = []
    until bomb_array.length == 10
      bomb_coords = [rand(9), rand(9)]  #REV nice way to randomly place bombs
      unless bomb_array.include?(bomb_coords)
        bomb_array << bomb_coords
      end
    end
    bomb_array
  end

  def set_square(coords, value)
    @matrix[coords[0]][coords[1]][:display] = value
  end

  def display_square(coords)
    @matrix[coords[0]][coords[1]]
  end

  def find_neighbors(coords)
    #REV personally I think that if you have so many offsets, might be better to do something like
    # -1.upto(1) do |x_offset|
    #   -1.upto(1) do |y_offset|
    # ...
    # kind of thing. but this is also a good way to do it
    vectors = [[-1,-1],[-1,0],[-1,1],[0,-1],[0,1],[1,-1],[1,0],[1,1]]
    neighbors = []
    vectors.each do |vector|
      unless ((coords[0]+vector[0]) < 0 || (coords[1]+vector[1]) < 0) || ((coords[0]+vector[0]) > 8 || (coords[1]+vector[1]) > 8)
        checking_x = coords[0]+vector[0]
        checking_y = coords[1]+vector[1]
        neighbors << [checking_x,checking_y]
      end
    end
    neighbors
  end

  def set_flag(coords)
    @matrix[coords[0]][coords[1]][:display] = "F"
  end

  def expose_square(coords)
    if is_bomb?(coords)   #REV the helper methods here are definitely very good
      set_square(coords, "B")
      lose
    elsif is_flag?(coords)
      puts "That is a Flag, pick another square!"
    elsif exposed?(coords)
      puts "Exposed, pick another square!"
    else
      update_square(coords)
    end
  end

  def exposed?(coords)  #REV great helper methods
    current_state = display_square(coords)[:display]
    current_state.is_a?(Fixnum) ? true : false
  end

  def is_bomb?(coords)
    @matrix[coords[0]][coords[1]][:b]
  end

  def is_flag?(coords)
    @matrix[coords[0]][coords[1]][:display] == "F" ? true : false
  end

  def update_square(coord)
    neighbors = find_neighbors(coord)
    bomb_num = neighbor_bomb_count(neighbors)
    set_square(coord, bomb_num)
    check_neighbors(neighbors) if bomb_num == 0
  end

  def check_neighbors(neighbors)
    neighbors.each do | neighbor |
      next if display_square(neighbor)[:b]
      next if display_square(neighbor)[:display].is_a?(Fixnum)
      update_square(neighbor)
    end
  end

  def neighbor_bomb_count(neighbors)
    bomb_num = 0
    neighbors.each do |neighbor|
      bomb_num += 1 if @matrix[neighbor[0]][neighbor[1]][:b]
    end
    bomb_num
  end

  def lose
    @lost = true
  end

  def win
    # find '*' if no '*' then all bombs are flagged, win!
    # REV might be more clear if you made a method like all_revealed? or something
    stars = []
    @matrix.length.times do | x |
      @matrix[0].length.times do | y |
        stars << '*' if @matrix[x][y][:display] == '*'
      end
    end
    @win = true if b.empty?
  end

  def game_over?
    true if @win || @lost
  end

end

class Minesweeper
  def initialize    #REV this constructor doesn't actually do anything, so its not required
    @board
  end

  def load_game
    puts "New Game or Load Game? (n/l)"   #REV the prompt here is nice
    start = gets.chomp.downcase

    if start=='l'
      load_file
    else
      @board = Board.new
      @board.set_bombs  #REV a bit weird that you call set_bombs and this is not done on Board construction
    end
    play
  end

  def play
    until @board.game_over?
      @board.display_board
      prompt_user
    end
    @board.display_board
    puts "Game over!"     #REV might be nice to know if user won or lost
  end

  def prompt_user
    puts "Reveal a square or flag a square? (r/f/s)\n"
    type_of_action = gets.chomp.downcase

    save if type_of_action == 's'

    puts "Pick a Coordinate" # user enters two numbers, one space, no comma
    coord = gets.chomp.split(' ').map(&:to_i)
    if type_of_action == 'f'
      @board.set_flag(coord)
    elsif type_of_action == 'r'
      @board.expose_square(coord)
    end
  end

  def load_file
    json = File.read('game.JSON')
    board_array = JSON.parse(json, symbolize_names: true)[:board]
    @board = Board.new(board_array)
  end

  def save
    File.open("game.json", "w") do |f|
      test = {"board" => @board.matrix }
      f.puts test.to_json
    end
    puts "Goodbye!"
    exit
  end
end

#REV file is over 200 lines long, definitely benefit from moving the classes into separate files

=begin
REV The way Minesweeper is made now, it is a little error prone. For example, the user could do
Minesweeper.new.play, in which case the @board is nil and program will crash. Consider making the
constructor of Minesweeper protected, and use factory methods to create an instance of Minesweeper.
for example:

def self.new_game
  Minesweeper.new(Board.new)
end

protected
def initialize(board)
  @board = board
end

REV great job overall
=end

m = Minesweeper.new
m.load_game



