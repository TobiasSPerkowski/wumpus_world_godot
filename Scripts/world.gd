extends Node
class_name World

var cells = []

@export var rows: int = 4
@export var columns: int = 4
@export var num_pits: int = 0
@export var num_wumpus: int = 0


func _ready():
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

	_add_pits()
	_add_wumpus()
	_add_gold()


func _add_pits():
	if num_pits > rows * columns:
		print("Too many pits! Try again with less or a bigger world.")
		get_tree().quit()
	var count = 0
	while count < num_pits:
		var x = 1 + (randi() % rows)
		var y = 1 + (randi() % columns)
		if cells[x][y].pit:
			continue
		cells[x][y].pit = true
		cells[x-1][y].breeze = true
		cells[x+1][y].breeze = true
		cells[x][y-1].breeze = true
		cells[x][y+1].breeze = true
		count += 1


func _add_wumpus():
	if num_wumpus > rows * columns:
		print("Too many wumpus! Try again with less or a bigger world.")
		get_tree().quit()
	var count = 0
	while count < num_wumpus:
		var x = 1 + (randi() % rows)
		var y = 1 + (randi() % columns)
		if cells[x][y].wumpus or cells[x][y].pit:
			continue
		cells[x][y].wumpus = true
		cells[x-1][y].stench = true
		cells[x+1][y].stench = true
		cells[x][y-1].stench = true
		cells[x][y+1].stench = true
		count += 1


func _add_gold():
	var done = false
	while not done:
		var x = 1 + (randi() % rows)
		var y = 1 + (randi() % columns)
		if cells[x][y].wumpus or cells[x][y].pit:
			continue
		cells[x][y].gold = true
		done = true


func _print_world():
	for row in cells:
		var str: String
		for cell in row:
			if cell.wall:
				str += " # "
			elif cell.gold:
				str += " G "
			elif cell.pit:
				str += " P "
			elif cell.wumpus:
				str += " W "
			elif cell.breeze or cell.stench:
				str += " ~ "
			else:
				str += " . "
		print(str)
