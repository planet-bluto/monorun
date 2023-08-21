extends Node

const LAST_DELTA = (1.0 / 60.0)

var managers = {}

func _process(delta):
#	var curr_fps = round(1.0 / delta)
#	if (curr_fps != 60):
#		print("FRAME DROP! FPS: %s" % curr_fps)
	for id in managers:
		var manager = managers[id]
		manager._update(delta)
