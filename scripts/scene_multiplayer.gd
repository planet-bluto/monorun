extends Node2D

const STATES = {
	0: "input_name",
	1: "choose_lobby"
}

var STATE = 0
var LobbyTemplate = preload("res://objects/LobbyTemplate.tscn")

func _ready():
	Network.start()
	Network.connect("connected", self, "_net_connected")
	
	$LobbyList/AddButton.connect("pressed", self, "_join_lobby")
	$LobbyList/HostButton.connect("button_up", self, "_host_lobby")
	$LobbyList/ReloadButton.connect("pressed", self, "_load_lobbies")

func _net_connected():
	$LoadingScreen.visible = false
	_load_lobbies()

func _load_lobbies():
	for child in $LobbyList/Container.get_children():
		child.queue_free()
	
	var lobbies = yield(Network.emit("get_lobbies"), "completed")
	for lobby in lobbies:
		var lobby_elem = LobbyTemplate.instance()
		lobby_elem.lobby = lobby
		$LobbyList/Container.add_child(lobby_elem)
		print(lobby)
		lobby_elem.get_node("JoinButton").connect("pressed", self, "_join_lobby", [lobby.id])

func _join_lobby(lobby_id):
	var lobby = yield(Network.emit("join_lobby", {"id": lobby_id, "username": Network.username}), "completed")
	Network.lobby = lobby
	Network.setup()
	get_tree().change_scene("res://scenes/lobby.tscn")
#	yield(Network, "setup_completed")

func _host_lobby():
	var new_lobby = {
		"title": ("%s's Lobby" % Network.username),
	}
	var callbacked_lobby = yield(Network.emit("new_lobby", {"lobby": new_lobby, "username": Network.username}), "completed")
	if (callbacked_lobby != null):
		Network.id = 1
		Network.lobby = callbacked_lobby
		Network.lobby.clients
		Network.rtc_connected = true
		Network.setup()
#		yield(Network, "setup_completed")
		get_tree().change_scene("res://scenes/lobby.tscn")

func _process(_delta):
	material.set_shader_param("MOOD_COLOR", GlobalVars.mood_color)
	$Background.color = GlobalVars.mood_color
	$Crosshair.position = get_global_mouse_position()
	
	
	if (STATE == 0):
		if (Input.is_action_just_pressed("CONFIRM") and $PlayerInfo/Nickname.text.length() > 0):
			Network.username = $PlayerInfo/Nickname.text
			$PlayerInfo.visible = false
			$LobbyList.visible = true
