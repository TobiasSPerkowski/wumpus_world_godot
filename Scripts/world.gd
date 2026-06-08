extends Node2D
class_name World

const GameStatus = Enums.GameStatus

var status = GameStatus.LOADING

## global path to a map file (leaving blank will generate a random map)
@export var map_path: String
## number of arrows the player will start with
@export var num_arrows: int = 2


func _ready():
	randomize()
	
	$Map.load_from_file(map_path)
	_init_player()
	
	#_set_scale()
	RenderingServer.set_default_clear_color(Color.BLACK)
	
	$Player.arrows += num_arrows
	$Advisor.got_arrows(num_arrows)
	status = GameStatus.PLAYING


func _init_player():
	var coords = $Map.get_player_coords()
	
	$Player.position.x = coords.x * Cell.size + Cell.size/2
	$Player.position.y = coords.y * Cell.size + Cell.size/2


func _input(event: InputEvent):
	if event.is_action_pressed("move_forward"):
		if not _is_safe_move():
			$Map.change_forward_cell($Player.dir)
		_handle_movement()
	elif event.is_action_pressed("turn_left"):
		$Player.turn_left()
		$Advisor.player_turned("l")
	elif event.is_action_pressed("turn_right"):
		$Player.turn_right()
		$Advisor.player_turned("r")
	elif event.is_action_pressed("shoot"):
		$Player.shoot_arrow()
		var hit = $Map.shot_hit($Player.dir)
		$Advisor.player_shot(hit)
	elif event.is_action_pressed("hint"):
		_get_hint()


func _handle_movement():
	var dir = $Player.dir
	if not $Map.wall_collision(dir): 
		if $Player.move_forward():
			status = $Map.update(dir)
			if status == GameStatus.LOST:
				#$Player.hide()
				get_tree().paused = true
				print("GAME OVER")
			elif status == GameStatus.WON:
				#$Player.hide()
				get_tree().paused = true
				print("YOU WIN")
			$Advisor.send_sensors($Map.get_player_cell(), false)
	else:
		$Advisor.send_sensors($Map.get_player_cell(), true)


func _get_hint():
	var move = $Advisor.query("h")
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
	
	$Map.hint(dx, dy, shoot)


func _is_safe_move() -> bool:
	# checks safety with advisor	
	var safe = $Advisor.query("c")
	if safe == "True":
		return true
		
	return false
