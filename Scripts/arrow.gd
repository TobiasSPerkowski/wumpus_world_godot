extends Node2D

const Directions = Enums.Directions

var dir: Directions
var speed = 128 


func set_dir(d: Directions):
	dir = d
	
	if dir == Directions.NORTH:
		$Sprite.rotation_degrees = -90
	elif dir == Directions.SOUTH:
		$Sprite.rotation_degrees = 90
	elif dir == Directions.EAST:
		$Sprite.rotation_degrees = 0
	else:
		$Sprite.rotation_degrees = 180


func _process(delta: float):
	if dir == Directions.NORTH:
		position.y -= speed * delta
	elif dir == Directions.SOUTH:
		position.y += speed * delta
	elif dir == Directions.EAST:
		position.x += speed * delta
	elif dir == Directions.WEST:
		position.x -= speed * delta


func _on_screen_exited():
	queue_free()
