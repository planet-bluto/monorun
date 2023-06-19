extends Node

class_name InputManager

signal pressed(key)
signal released(key)

var type = -1

# Make Player Script more Event-Based to SOLVE EVERY FUCKING PROBLEM ON JAWN

const TO_BOOL = {
	"1": true,
	"2": false
}

var keys = {
	"U": false,
	"D": false,
	"L": false,
	"R": false,
	"DASH": false,
	"JUMP": false,
	"SHOOT": false,
	"ALT": false
}

func _init(t, id):
	type = t
	GlobalInputManager.managers[id] = self
	#######
	var _1 = connect("pressed", self, "_on_pressed")
	var _2 = connect("released", self, "_on_released")

func _update(_delta):
	if (type == 0):
#		_check()
		for key in keys:
			if (Input.is_action_just_pressed(key)):
				_handle_press(key)
			if (Input.is_action_just_released(key)):
				_handle_release(key)

func is_down(key):
	return keys[key]

func decode(string):
#	var states = Array(string.split(""))
	var connum = string.length()-1
	var ind = string.substr(0, connum)
	var bol = string[connum]
	if (bol == "1"):
#		print("PRESS ONE NIGGA")
		_handle_press(ind)
	elif (bol == "2"):
#		print("PRESS TWO NIGGA")
		_handle_release(ind)
#	print(keys)

func _handle_press(key):
	if (type == 0):
		_on_input(key, 1)
#		yield(OneShotTimer.start(0.001*WsClient.ping), "timeout")
	emit_signal("pressed", key)
	keys[key] = true

func _handle_release(key):
	if (type == 0):
		_on_input(key, 2)
#		yield(OneShotTimer.start(0.001*WsClient.ping), "timeout")
	emit_signal("released", key)
	keys[key] = false

func _on_pressed(_key):
#	_on_input(key, 1)
	pass

func _on_released(_key):
#	_on_input(key, 2)
	pass

func _on_input(_key, _state):
	pass

func get_tree():
	return GlobalVars.tree
