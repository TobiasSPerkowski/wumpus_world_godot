extends Node
class_name World

var cells = []

@export var rows: int
@export var columns: int
@export var num_pits: int
@export var num_wumpus: int


func _ready():
	assert(rows != null)
	assert(columns != null)
	
	randomize()
	
	_generate_world()
	_print_world()


func _generate_world():
	var size_x = rows + 2   # padding for walls
	var size_y =columns + 2 # padding for walls
	# create cells
	for i in range(size_x):
		var row = []
		for j in range(size_y):
			var c = Cell.new()
			if i == 0 or i == size_x-1 or j == 0 or j == size_y-1:
				c.wall = true
			row.append(c)
		cells.append(row)
	# add pits
	_add_pits()


func _add_pits():
	if num_pits > rows * columns:
		print("Too many pits! Try again with less or a bigger world.")
		get_tree().quit()
	var count = 0
	while count < num_pits:
		var x = 1 + (randi() % rows)
		var y = 1 + (randi() % columns)
		if cells[x][y].pit:
			print(cells[x][y].pit)
			continue
		cells[x][y].pit = true
		cells[x-1][y].breeze = true
		cells[x+1][y].breeze = true
		cells[x][y-1].breeze = true
		cells[x][y+1].breeze = true
		count += 1


func _print_world():
	for row in cells:
		var str: String
		for cell in row:
			if cell.wall:
				str += " | "
			elif cell.pit:
				str += " o "
			elif cell.breeze:
				str += " ~ "
			else:
				str += "   "
		print(str)
