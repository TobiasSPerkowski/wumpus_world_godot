extends Node2D
class_name World

var cells = []
var cell_scene = preload("res://Scenes/cell.tscn")
var cell_size = 16
var player_x = 1
var player_y = 1

@export var rows: int = 4
@export var columns: int = 4
@export var num_pits: int = 0
@export var num_wumpus: int = 0


func _ready():
	randomize()
	
	_set_scale()
	_generate_world()
	#_print_world()
	_init_player(player_x, player_y)
	#cells[1][1].show_sprites()

func _set_scale():
	var scale_x = get_window().size.x / (cell_size * (rows+2))
	var scale_y = get_window().size.y / (cell_size * (columns+2))
	if scale_x < scale_y:
		scale *= scale_x
	else:
		scale *= scale_y


func _generate_world():
	var size_x = rows + 2   # padding for walls
	var size_y =columns + 2 # padding for walls
	# create cells
	for i in range(size_x):
		var row = []
		for j in range(size_y):
			var c = cell_scene.instantiate()
			if i == 0 or i == size_x-1 or j == 0 or j == size_y-1:
				c.wall = true
			row.append(c)
			c.position.x = 8 + i * cell_size
			c.position.y = 8 + j * cell_size
			add_child(c)
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


func _init_player(x: int, y: int):
	if x > columns:
		x = columns
	if y > rows:
		y = rows
	
	$Player.position.x += x * cell_size
	$Player.position.y += y * cell_size


func _input(event: InputEvent):
	if event.is_action_pressed("move_forward"):
		if not _wall_collision(): 
			$Player.move_forward()
			_update()
	elif event.is_action_pressed("turn_left"):
		$Player.turn_left()
	elif event.is_action_pressed("turn_right"):
		$Player.turn_right()


func _wall_collision() -> bool:
	var x = player_x
	var y = player_y
	var dir = $Player.dir
	
	if dir == $Player.Directions.NORTH and cells[x][y-1].wall:
		cells[x][y-1].show_sprites()
		return true
	if dir == $Player.Directions.SOUTH and cells[x][y+1].wall:
		cells[x][y+1].show_sprites()
		return true
	if dir == $Player.Directions.EAST and cells[x+1][y].wall:
		cells[x+1][y].show_sprites()
		return true
	if dir == $Player.Directions.WEST and cells[x-1][y].wall:
		cells[x-1][y].show_sprites()
		return true
		
	return false


func _update():
	var dir = $Player.dir
	
	if dir == $Player.Directions.NORTH:
		player_y -= 1
	elif dir == $Player.Directions.SOUTH:
		player_y += 1
	elif dir == $Player.Directions.EAST:
		player_x += 1
	else:
		player_x -= 1
	
	var c = cells[player_x][player_y]
	c.show_sprites()
	if c.pit or c.wumpus:
		$Player.hide()
		print("GAME OVER")
