extends Node2D
class_name Player

const Directions = Enums.Directions

var moving := false
var dir := Directions.EAST
var target_rot := 0.0
var target_pos : Vector2
var cell_size

@export var speed := 10.0


func _process(delta: float):
	_rotate(delta)
	
	if moving:
		_move(delta)


func _rotate(delta: float):
	if target_rot == null:
		return
	
	$Sprite.rotation = lerp_angle($Sprite.rotation, target_rot, delta*speed)


func _move(delta: float):
	position = position.lerp(target_pos, delta*speed)
	
	if position.distance_to(target_pos) < 1:
		position = target_pos
		moving = false


func turn_left():
	if dir == Directions.NORTH:
		dir = Directions.WEST
	elif dir == Directions.SOUTH:
		dir = Directions.EAST
	elif dir == Directions.EAST:
		dir = Directions.NORTH
	elif dir == Directions.WEST:
		dir = Directions.SOUTH
		
	_update_sprite()


func turn_right():
	if dir == Directions.NORTH:
		dir = Directions.EAST
	elif dir == Directions.SOUTH:
		dir = Directions.WEST
	elif dir == Directions.EAST:
		dir = Directions.SOUTH
	elif dir == Directions.WEST:
		dir = Directions.NORTH
	
	_update_sprite()


func _update_sprite():
	if dir == Directions.NORTH:
		target_rot = -PI/2
	elif dir == Directions.SOUTH:
		target_rot = PI/2
	elif dir == Directions.EAST:
		target_rot = 0
		$Sprite.flip_v = false
	elif dir == Directions.WEST:
		target_rot = PI
		$Sprite.flip_v = true


func move_forward() -> bool:
	if moving:
		return false # needs to finish current movement
	
	var x
	var y
	
	if dir == Directions.NORTH:
		x = position.x
		y = position.y - Cell.size
	elif dir == Directions.SOUTH:
		x = position.x
		y = position.y + Cell.size
	elif dir == Directions.EAST:
		x = position.x + Cell.size
		y = position.y
	else: # WEST
		x = position.x - Cell.size
		y = position.y
	
	target_pos = Vector2(x, y)
	moving = true
	
	return true
