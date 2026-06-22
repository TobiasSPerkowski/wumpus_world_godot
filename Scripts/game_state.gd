extends Node

const GameStatus = Enums.GameStatus

signal status_changed(value)
signal arrows_changed(value)
signal hints_changed(value)
signal sensors_sent(sensors)
signal message(text)

var selected_map : String
var debug := false

var status := GameStatus.LOADING:
	set(value):
		status = value
		status_changed.emit(value)

var arrows := 0:
	set(value):
		arrows = value
		arrows_changed.emit(value)

var hints := 0:
	set(value):
		hints = value
		hints_changed.emit(value)
