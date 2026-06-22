extends CanvasLayer
class_name HUD

const GameStatus = Enums.GameStatus

func _ready():
	GameState.status_changed.connect(_on_status_changed)
	GameState.arrows_changed.connect(_on_arrows_changed)
	GameState.hints_changed.connect(_on_hints_changed)
	GameState.sensors_sent.connect(_on_sensors_sent)
	GameState.message.connect(_on_message)


func _on_status_changed(status: GameStatus):
	if status == GameStatus.LOST:
		$Messages/Text.text = "Fim de jogo: Você Perdeu.\nAperte ESC para voltar ao menu."
	elif status == GameStatus.WON:
		$Messages/Text.text = "Fim de jogo: Você Venceu!\nAperte ESC para voltar ao menu."
	
	
	


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


func _on_message(text: String):
	$Messages/Text.text = text
