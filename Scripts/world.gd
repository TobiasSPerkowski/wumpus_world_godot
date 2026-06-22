extends Node2D
class_name World

const GameStatus = Enums.GameStatus

## number of arrows the player will start with
@export var num_arrows: int = 3
## number of hints the player will start with
@export var num_hints: int = 3


func _ready():
	randomize()
	
	$Map.load_from_file(GameState.selected_map)
	_init_player()
	
	$Advisor.got_arrows(num_arrows)
	
	GameState.arrows = num_arrows
	GameState.hints = num_hints
	GameState.status = GameStatus.PLAYING


func _init_player():
	var coords = $Map.get_player_coords()
	
	$Player.position.x = coords.x * Cell.size + Cell.size/2
	$Player.position.y = coords.y * Cell.size + Cell.size/2


func _input(event: InputEvent):
	if GameState.status == GameStatus.PLAYING:
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
			if $Player.shoot_arrow():
				var scream = $Map.shot_hit($Player.dir)
				$Advisor.player_shot(scream)
			else:
				print("NO MORE ARROWS")  
		elif event.is_action_pressed("hint"):
			_get_hint()
	
	elif event.is_action_pressed("exit"):
		get_tree().change_scene_to_file("res://Scenes/menu.tscn")


func _handle_movement():
	var dir = $Player.dir
	if not $Map.wall_collision(dir): 
		if $Player.move_forward():
			GameState.status = $Map.update(dir)
			if GameState.status == GameStatus.LOST:
				$Player.hide()
				GameState.status = GameStatus.LOST
			elif GameState.status == GameStatus.WON:
				$Player.hide()
				GameState.status = GameStatus.WON
			$Advisor.send_sensors($Map.get_player_cell(), false)
	else:
		$Player.bump()
		$Advisor.send_sensors($Map.get_player_cell(), true)


func _get_hint():
	if GameState.hints <= 0:
		GameState.message.emit("Sem mais dicas")
		return
	
	GameState.hints -= 1
	
	var move = $Advisor.query("h")
	var shoot = false
	var dx
	var dy
	
	move = move.split(",")
	
	if move[0] == "e":
		GameState.message.emit("Sem solução")
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
