extends Node2D
class_name Player

const Directions = Enums.Directions

var dir := Directions.EAST


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
		$Sprite.rotation_degrees = -90
		$Sprite.flip_h = false
	elif dir == Directions.SOUTH:
		$Sprite.rotation_degrees = 90
		$Sprite.flip_h = false
	elif dir == Directions.EAST:
		$Sprite.rotation_degrees = 0
		$Sprite.flip_h = false
	elif dir == Directions.WEST:
		$Sprite.rotation_degrees = 0
		$Sprite.flip_h = true


func move_forward():
	if dir == Directions.NORTH:
		position.y -= 16
	elif dir == Directions.SOUTH:
		position.y += 16
	elif dir == Directions.EAST:
		position.x += 16
	else:
		position.x -= 16
