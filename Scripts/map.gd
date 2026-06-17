extends Node
class_name Map

const Directions = Enums.Directions
const GameStatus = Enums.GameStatus

var rows = 0
var columns = 0
var cells = []
var player_x = 1
var player_y = 1
var cell_scene = preload("res://Scenes/cell.tscn")


func load_from_file(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	
	if file == null:
		push_error("Error loading map: file not found")
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
	cells[player_y][player_x].show_sprites()
	if GameState.debug:
		for line in cells:
			for cell in line:
				cell.show_sprites()


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


func change_forward_cell(dir: Directions):
	var fx = player_x
	var fy = player_y
	
	if dir == Directions.NORTH:
		fy-=1
	elif dir == Directions.SOUTH:
		fy+=1
	elif dir == Directions.EAST:
		fx+=1
	else: # west
		fx-=1
	
	var c_cell = cells[player_y][player_x]
	var f_cell = cells[fy][fx]
	
	if c_cell.breeze:
		f_cell.turn_into_pit()
	else: # stench
		f_cell.turn_into_wumpus()


func get_player_cell() -> Cell:
	return cells[player_y][player_x]


func get_player_coords() -> Vector2i:
	return Vector2i(player_x, player_y)


func hint(dx: int, dy:int, shoot: bool):
	cells[player_y+dy][player_x+dx].hint(shoot)


func wall_collision(dir: Directions) -> bool:
	var col = player_x
	var row = player_y
	
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


func shot_hit(dir: Directions) -> bool:
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
	
	return hit


func update(dir: Directions) -> GameStatus:
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
		return GameStatus.LOST
		
	if c.gold:
		return GameStatus.WON
	
	return GameStatus.PLAYING
