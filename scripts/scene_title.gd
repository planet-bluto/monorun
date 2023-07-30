extends Node2D

const font = preload("res://misc/font_shortstack.tres")

export  var COLOR = Color("#e03c28")

var stage_width = 0
var current_button = "Local"
var buttons = ["Local", "Online", "Custom", "Options"]
var overrides = ["font_color_focus", "font_color_hover", "font_color_pressed"]

func _ready():
	var Xs = []
	for cell in $TileMap.get_used_cells():
		if ( not Xs.has(cell.x)):
			Xs.append(cell.x)
	stage_width = (Xs.size() * 80)
	var l_TileMap = $TileMap.duplicate()
	var r_TileMap = $TileMap.duplicate()
	add_child(l_TileMap)
	add_child(r_TileMap)
	l_TileMap.position.x -= stage_width
	r_TileMap.position.x += stage_width
	$Background.rect_position.x = - (8 * 80) - stage_width
	$Background.rect_position.y = - 720
	$Background.rect_size.x = stage_width * 3
	$Background.rect_size.y = 720
	
	$Camera/Local.grab_focus()
	for button in buttons:
		var btn_node = $Camera.get_node(button)
		btn_node.connect("mouse_entered", self, "_focus_button", [btn_node, button])
		btn_node.connect("pressed", self, "selection", [button])

func _process(delta):
	$Crosshair.position = get_global_mouse_position()
	
	$Camera.position.x += 16
	$"Camera/Player_-1/Anim".play("run")
	if ($Camera.position.x > stage_width):
		$Camera.position.x = 0
	
	$Background.color = GlobalVars.mood_color
	for button in buttons:
		for override in overrides:
			var btn_node = $Camera.get_node(button)
			btn_node.add_color_override(override, COLOR)
			btn_node.add_color_override(override, COLOR)
			font.outline_color = GlobalVars.mood_color
			btn_node.add_font_override("font", font)
	material.set_shader_param("PLAYER_COLOR", COLOR)
	material.set_shader_param("MOOD_COLOR", GlobalVars.mood_color)
	$TileMap.material.set_shader_param("MOOD_COLOR", GlobalVars.mood_color)

func _focus_button(btn_node, btn_name):
	current_button = btn_name
	$Camera/Anim.play(btn_name)
	btn_node.grab_focus()

func selection(btn_name):
	match btn_name:
		"Local":
			get_tree().change_scene("res://scenes/test.tscn")
		"Online":
			get_tree().change_scene("res://scenes/multiplayer.tscn")
		"Custom":
			pass
		"Options":
			pass
