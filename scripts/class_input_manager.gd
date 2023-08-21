extends Node

class_name InputManager

signal pressed(key)
signal released(key)

var type = - 1



const TO_BOOL = {
	"1":true, 
	"2":false
}

var keys = {
	"U":false, 
	"D":false, 
	"L":false, 
	"R":false, 
	"DASH":false, 
	"JUMP":false, 
	"SHOOT":false, 
	"ALT":false
}

var timers = {
	"U":0, 
	"D":0, 
	"L":0, 
	"R":0, 
	"DASH":0, 
	"JUMP":0, 
	"SHOOT":0, 
	"ALT":0
}

func _init(t, id):
	type = t
	GlobalInputManager.managers[id] = self
	
	connect("pressed", self, "_on_pressed")
	connect("released", self, "_on_released")

func _update(_delta):
	if (type == 0):
		
		for key in keys:
			if (Input.is_action_pressed(key)):
				timers[key] += 1
			if (Input.is_action_just_pressed(key)):
				_handle_press(key)
			if (Input.is_action_just_released(key)):
				_handle_release(key)
				timers[key] = 0

func is_down(key):
	return keys[key]

func decode(string):

	var connum = string.length() - 1
	var ind = string.substr(0, connum)
	var bol = string[connum]
	if (bol == "1"):

		_handle_press(ind)
	elif (bol == "2"):

		_handle_release(ind)

func _handle_press(key):
	if (type == 0):
		_on_input(key, 1)

	emit_signal("pressed", key)
	keys[key] = true

func _handle_release(key):
	if (type == 0):
		_on_input(key, 2)

	emit_signal("released", key)
	keys[key] = false

func _on_pressed(key):

	pass

func _on_released(key):

	pass

func _on_input(key, state):
	pass


func get_tree():
	return GlobalVars.tree
