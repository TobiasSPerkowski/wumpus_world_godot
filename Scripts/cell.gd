extends Node2D
class_name Cell

var stench: bool = false
var breeze: bool = false
var gold: bool = false
var wall: bool = false
var wumpus: bool = false
var pit: bool = false


func _to_string() -> String:
	var str: String
	
	if stench: 
		str += "1"
	else:
		str += "0"
	
	if breeze: 
		str += "1"
	else:
		str += "0"
	
	if gold: 
		str += "1"
	else:
		str += "0"
	
	if wall: 
		str += "1"
	else:
		str += "0"
	
	if wumpus: 
		str += "1"
	else:
		str += "0"
	
	if pit: 
		str += "1"
	else:
		str += "0"
	
	return str


func show_sprites():
	if wall:
		$Wall.visible = true
		return
		
	if gold:
		$Gold.visible = true
	elif pit:
		$Pit.visible = true
	elif wumpus:
		$Wumpus.visible = true
		
	if breeze:
		$Breeze.visible = true
		
	if stench:
		$Stench.visible = true
