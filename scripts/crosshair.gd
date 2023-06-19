extends Sprite
class_name Crosshair

func _ready():
	texture = preload("res://sprites/crosshair.png")
	texture.flags = 0
	
	z_index = 1000

func _process(_delta): position = get_global_mouse_position()
