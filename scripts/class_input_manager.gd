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
	"JUMP": false
}

func _init(t, id):
	type = t
	print(id)
	GlobalInputManager.managers[id] = self
	#######
	connect("pressed", self, "_on_pressed")
	connect("released", self, "_on_released")

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

func _on_pressed(key):
#	_on_input(key, 1)
	pass

func _on_released(key):
#	_on_input(key, 2)
	pass

func _on_input(key, state):
	if (WsClient.connected and type == 0):
		var sock_string = "i:" + str(key) + str(state) + ",%s" % MonoBase.fromDec(Date.now())
		WsClient.send(sock_string) 

func get_tree():
	return GlobalVars.tree
