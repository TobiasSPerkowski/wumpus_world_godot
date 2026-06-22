extends Node
class_name Advisor

var exec_path = ProjectSettings.globalize_path("res://Advisor/advisor")
var process

func _ready():
	process = OS.execute_with_pipe(exec_path, [], false)
	#process = OS.execute_with_pipe("python3", ["Advisor/advisor.py"], false)


#func _process(delta: float) -> void:
	#print(process["stderr"].get_line())


func player_turned(dir: String):
	if dir == "l" or dir == "r":
		process["stdio"].store_line(dir)


func player_shot(scream: bool):
	if scream:
		GameState.message.emit("Você ouve um grito")
		process["stdio"].store_line("s 1")
	else:
		GameState.message.emit("Você não ouve nada")
		process["stdio"].store_line("s 0")


func got_arrows(num: int):
	process["stdio"].store_line("a " + str(num))


func send_sensors(c: Cell, bump: bool):
	var stench = "1" if c.stench else "0"
	var breeze = "1" if c.breeze else "0"
	var wall = "1" if bump else "0"
	var sensors = "".join([stench, breeze, wall])
	
	process["stdio"].store_line(sensors)
	GameState.sensors_sent.emit(sensors)


func query(opt: String) -> String:
	if opt != "h" and opt != "c":
		return "invalid option"
	
	process["stdio"].store_line(opt)
	
	var output = ""
	while output == "":
		output = process["stdio"].get_line()
	
	return output


func _exit_tree():
	var pid = process["pid"]
	
	if pid != 0:
		OS.kill(pid)
