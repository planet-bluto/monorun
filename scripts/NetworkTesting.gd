extends Node

func _ready():
	Network.start()
	Network.connect("connected", self, "_net_connected")

func _net_connected():
	Network.send_mode = "RTC"
	var lobbies = yield(Network.emit("get_lobbies"), "completed")[0]
	
	print("[ Got Lobbies? ]")
	print(lobbies)
