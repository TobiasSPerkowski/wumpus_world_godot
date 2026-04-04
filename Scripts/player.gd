extends Node2D
class_name Player

enum Directions {NORTH, SOUTH, EAST, WEST}

var dir := Directions.NORTH


func turn_left():
	if dir == Directions.NORTH:
		dir = Directions.WEST
	elif dir == Directions.SOUTH:
		dir = Directions.EAST
	elif dir == Directions.EAST:
		dir = Directions.NORTH
	elif dir == Directions.WEST:
		dir = Directions.SOUTH
		
	$Sprite.rotation_degrees -= 90


func turn_right():
	if dir == Directions.NORTH:
		dir = Directions.EAST
	elif dir == Directions.SOUTH:
		dir = Directions.WEST
	elif dir == Directions.EAST:
		dir = Directions.SOUTH
	elif dir == Directions.WEST:
		dir = Directions.NORTH
	
	$Sprite.rotation_degrees += 90


func move_forward():
	if dir == Directions.NORTH:
		position.y -= 16
	elif dir == Directions.SOUTH:
		position.y += 16
	elif dir == Directions.EAST:
		position.x += 16
	else:
		position.x -= 16
