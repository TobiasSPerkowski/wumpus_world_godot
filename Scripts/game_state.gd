extends Node

const GameStatus = Enums.GameStatus

signal arrows_changed(value)
signal hints_changed(value)
signal sensors_sent(sensors)
signal exception(text)

var status := GameStatus.LOADING
var selected_map : String
var debug := false

var arrows := 0:
	set(value):
		arrows = value
		arrows_changed.emit(value)

var hints := 0:
	set(value):
		hints = value
		hints_changed.emit(value)
