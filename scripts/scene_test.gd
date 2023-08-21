extends Node2D

export  var mood_color_override = Color(0, 0, 0)

onready var background_node = $Background

func _ready():
	pass

func _process(delta): pass

#func _process(delta):
#	material.set_shader_param("MOOD_COLOR", GlobalVars.mood_color)
#	$Background.color = GlobalVars.mood_color
	
#	$Crosshair.position = get_global_mouse_position()

#func add_line(text):
#	var lines = $VP/Label.get_line_count()
#	if (lines == 11):
#		var textArr = $VP/Label.text.split("\n")
#		textArr.remove(0)
#		$VP/Label.text = textArr.join("\n")
#	if ($VP/Label.text == ""):
#		$VP/Label.text += text
#	else :
#		$VP/Label.text += "\n" + text
