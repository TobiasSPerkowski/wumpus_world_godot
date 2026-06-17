extends Control
class_name Menu

@export var maps_path := "Maps"
@onready var map_list := %MapList


func _ready():
	RenderingServer.set_default_clear_color(Color.BLACK)


func _on_play_pressed() -> void:
	%Main.visible = false
	%Help.visible = false
	%MapSelecton.visible = true
	_show_maps()


func _on_help_pressed():
	%Main.visible = false
	%MapSelecton.visible = false
	%Help.visible = true


func _on_back_pressed():
	%MapSelecton.visible = false
	%Help.visible = false
	%Main.visible = true


func _on_quit_pressed():
	get_tree().quit()


func _show_maps():
	var dir = DirAccess.open(maps_path)
	
	if dir == null:
		return
	
	dir.list_dir_begin()
	
	var map_file = dir.get_next()
	
	while map_file != "":
		_add_map_button(map_file)
		map_file = dir.get_next()
	
	dir.list_dir_end()


func _add_map_button(map_file: String):
	var button = Button.new()
	
	button.text = map_file.get_basename()
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(_on_map_selected.bind(map_file))
	
	map_list.add_child(button)


func _on_map_selected(map_file: String):
	GameState.selected_map = maps_path + "/" + map_file
	get_tree().change_scene_to_file("res://Scenes/world.tscn")
	pass
