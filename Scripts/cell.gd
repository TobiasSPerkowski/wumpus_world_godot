extends Node2D
class_name Cell

static var size = 16

var stench := false
var breeze := false
var gold := false
var wall := false
var wumpus := false
var pit := false


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
	$Floor.visible = true
	$Hint.visible = false
	
	$Wall.visible = wall
	if wall:
		return
	
	$Gold.visible = gold
	$Pit.visible = pit
	$Wumpus.visible = wumpus
	$Breeze.visible = breeze
	$Stench.visible = stench


func hint(shoot: bool):
	if shoot:
		$Hint.modulate = Color.RED
	else:
		$Hint.modulate = Color.GREEN
	
	$Hint.visible = true


func turn_into_pit():
	stench = false
	breeze = false
	gold = false
	wall = false
	wumpus = false
	pit = true


func turn_into_wumpus():
	stench = false
	breeze = false
	gold = false
	wall = false
	wumpus = true
	pit = false
