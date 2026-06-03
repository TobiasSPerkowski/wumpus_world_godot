extends Node2D
class_name World

const Directions = Enums.Directions
const AdvisorPath = "Scripts/advisor.py"

var cells = []
var cell_scene = preload("res://Scenes/cell.tscn")
var arrow_scene = preload("res://Scenes/arrow.tscn") 
var player_x = 1
var player_y = 1
var action_timer: float
var advisor_proc
var advisor_action: String
var bumped_wall = false


## global path to a map file (leaving blank will generate a random map)
@export var map_path: String
## number of columns in the randomly generated map
@export var columns: int = 4
## number of rows in the randomly generated map
@export var rows: int = 4
## number of pits in the randomly generated map
@export var num_pits: int = 0
## number of wumpus in the randomly generated map
@export var num_wumpus: int = 0
## number of arrows the player will start with
@export var num_arrows: int = 2


func _ready():
	randomize()
	
	if map_path:
		_load_map()
	else:
		_generate_map()
	
	#_set_scale()
	_init_player()
	cells[player_y][player_x].show_sprites()
	RenderingServer.set_default_clear_color(Color.BLACK)
	
	advisor_proc = OS.execute_with_pipe("python3", ["-u", AdvisorPath], false)
	
	advisor_proc["stdio"].store_line("a " + str(num_arrows))


func _send_advisor_sensors():
	var c = cells[player_y][player_x]
	var stench = "1" if c.stench else "0"
	var breeze = "1" if c.breeze else "0"
	var gold = "1" if c.gold else "0"
	var wall = "1" if bumped_wall else "0"
	var sensors = "".join([stench, breeze, gold, wall])
	
	advisor_proc["stdio"].store_line(sensors)
	
	bumped_wall = false


func _set_scale():
	var scale_x = get_window().size.x / (Cell.size * (columns+2.0))
	var scale_y = get_window().size.y / (Cell.size * (rows+2.0))
	
	if scale_x < scale_y:
		scale *= scale_x
	else:
		scale *= scale_y


func _load_map():
	var file = FileAccess.open(map_path, FileAccess.READ)
	
	if file == null:
		push_error("Erro ao abrir arquivo")
		return
	
	var lines = []
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line != "":
			lines.append(line)
	
	file.close()
	
	columns = lines[0].length()
	rows = lines.size()
	
	_init_cells()
	_parse_map(lines)


func _init_cells():
	# + 2 -> padding for walls
	var size_x = columns + 2 
	var size_y = rows + 2
	
	for i in range(size_y):
		var row = []
		for j in range(size_x):
			var c = cell_scene.instantiate()
			if i == 0 or i == size_y-1 or j == 0 or j == size_x-1:
				c.wall = true
			row.append(c)
			c.position.x = 8 + j * Cell.size
			c.position.y = 8 + i * Cell.size
			add_child(c)
		cells.append(row)


func _parse_map(lines: Array):
	for i in range(rows):
		for j in range(columns):
			if lines[i][j] == '#':
				cells[i+1][j+1].wall = true
			elif lines[i][j] == 'S':
				player_x = j+1
				player_y = i+1
			elif lines[i][j] == 'G':
				cells[i+1][j+1].gold = true
			elif lines[i][j] == 'P':
				cells[i+1][j+1].pit = true
				cells[i][j+1].breeze = true
				cells[i+2][j+1].breeze = true
				cells[i+1][j].breeze = true
				cells[i+1][j+2].breeze = true
			elif lines[i][j] == 'W':
				cells[i+1][j+1].wumpus = true
				cells[i][j+1].stench = true
				cells[i+2][j+1].stench = true
				cells[i+1][j].stench = true
				cells[i+1][j+2].stench = true


func _generate_map():
	# create cells
	_init_cells()
	# populate cells
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


func _init_player():
	if player_x > columns:
		player_x = columns
	if player_y > rows:
		player_y = rows
	
	$Player.position.x = player_x * Cell.size + Cell.size/2
	$Player.position.y = player_y * Cell.size + Cell.size/2


func _input(event: InputEvent):
	if event.is_action_pressed("move_forward"):
		if not _is_safe_move():
			#_change_forward_cell()
			print("NOT SAFE")
		_handle_movement()
	elif event.is_action_pressed("turn_left"):
		$Player.turn_left()
		advisor_proc["stdio"].store_line("l")
	elif event.is_action_pressed("turn_right"):
		$Player.turn_right()
		advisor_proc["stdio"].store_line("r")
	elif event.is_action_pressed("shoot"):
		_shoot_arrow()
	elif event.is_action_pressed("hint"):
		_get_hint()
	elif event.is_action_pressed("debug"):
		var output = "a"
		advisor_proc["stdio"].store_line("d")
		while output != "":
			output = advisor_proc["stdio"].get_line()
			print(output)


func _change_forward_cell():
	var fx = player_x
	var fy = player_y
	
	if $Player.dir == Directions.NORTH:
		fy-=1
	elif $Player.dir == Directions.SOUTH:
		fy+=1
	elif $Player.dir == Directions.EAST:
		fx+=1
	else: # west
		fx-=1
	
	var c_cell = cells[player_y][player_x]
	var f_cell = cells[fy][fx]
	
	if c_cell.breeze:
		f_cell.turn_into_pit()
	else: # stench
		f_cell.turn_into_wumpus()
	


func _handle_movement():
	if not _wall_collision(): 
		if $Player.move_forward():
			_update()
			_send_advisor_sensors()
	else:
		bumped_wall = true
		_send_advisor_sensors()


func _query_advisor(input: String):
	var output = ""
	
	advisor_proc["stdio"].store_line(input)
	
	while output == "":
		output = advisor_proc["stdio"].get_line()
	
	return output

func _process(delta: float) -> void:
	print(advisor_proc["stderr"].get_line())

func _get_hint():
	var move = _query_advisor("h")
	var shoot = false
	var dx
	var dy
	
	move = move.split(",")
	
	if move[0] == "e":
		print("GIVE UP")
		return
	if move[0] == "s":
		shoot = true
		dy = move[1].to_int()
		dx = move[2].to_int()
	else:
		dy = move[0].to_int()
		dx = move[1].to_int()
	
	cells[player_y+dy][player_x+dx].hint(shoot)


func _is_safe_move() -> bool:
	# checks safety with advisor	
	var safe = _query_advisor("c")
	if safe == "True":
		return true
		
	return false


func _wall_collision() -> bool:
	var col = player_x
	var row = player_y
	var dir = $Player.dir
	
	if dir == Directions.NORTH and cells[row-1][col].wall:
		cells[row-1][col].show_sprites()
		return true
	if dir == Directions.SOUTH and cells[row+1][col].wall:
		cells[row+1][col].show_sprites()
		return true
	if dir == Directions.EAST and cells[row][col+1].wall:
		cells[row][col+1].show_sprites()
		return true
	if dir == Directions.WEST and cells[row][col-1].wall:
		cells[row][col-1].show_sprites()
		return true
		
	return false


func _shoot_arrow():
	var dir = $Player.dir
	var hit = false
	
	# scanning for wumpus in shot direction
	if dir == Directions.NORTH:
		for i in range(player_y-1, 0, -1):
			if cells[i][player_x].wumpus:
				cells[i][player_x].wumpus = false
				hit = true
	elif dir == Directions.SOUTH:
		for i in range(player_y+1, rows+1, 1):
			if cells[i][player_x].wumpus:
				cells[i][player_x].wumpus = false
				hit = true
	elif dir == Directions.EAST:
		for i in range(player_x+1, columns+1, +1):
			if cells[player_y][i].wumpus:
				cells[player_y][i].wumpus = false
				hit = true
	else:
		for i in range(player_x-1, 0, -1):
			if cells[player_y][i].wumpus:
				cells[player_y][i].wumpus = false
				hit = true
	
	# informing the advisor
	if hit:
		advisor_proc["stdio"].store_line("s 1")
		print("* SCREAM *")
	else:
		advisor_proc["stdio"].store_line("s 0")
		print("........")
	
	# animation
	var a = arrow_scene.instantiate()
	a.set_dir(dir)
	$Player.add_child(a)


func _update():
	var dir = $Player.dir
	
	if dir == Directions.NORTH:
		player_y -= 1
	elif dir == Directions.SOUTH:
		player_y += 1
	elif dir == Directions.EAST:
		player_x += 1
	else:
		player_x -= 1
	
	var c = cells[player_y][player_x]
	c.show_sprites()
	
	if c.pit or c.wumpus:
		$Player.hide()
		get_tree().paused = true
		print("GAME OVER")
	elif c.gold:
		$Player.hide()
		get_tree().paused = true
		print("YOU WIN")
