extends CanvasLayer
class_name HUD


func _ready():
	GameState.arrows_changed.connect(_on_arrows_changed)
	GameState.hints_changed.connect(_on_hints_changed)
	GameState.sensors_sent.connect(_on_sensors_sent)
	GameState.exception.connect(_on_exception)


func _on_arrows_changed(val: int):
	$Arrows/Value.text = str(val)


func _on_hints_changed(val: int):
	$Hints/Value.text = str(val)


func _on_sensors_sent(sensors: String):
	if sensors.substr(0,2) == "10":
		$Sensors/Value.text = "Fedor"
	elif sensors.substr(0,2) == "01":
		$Sensors/Value.text = "Brisa"
	elif sensors.substr(0,2) == "11":
		$Sensors/Value.text = "Fedor e Brisa"
	else:
		$Sensors/Value.text = "Vazia"


func _on_exception(text: String):
	$Messages/Text.text = text
