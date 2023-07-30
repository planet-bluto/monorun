extends Node2D

const STATES = {
	0: "input_name",
	1: "choose_lobby"
}

var STATE = 0
var LobbyTemplate = preload("res://objects/LobbyTemplate.tscn")

func _ready():
	$LobbyList/AddButton.connect("pressed", self, "_join_lobby")
	$LobbyList/HostButton.connect("button_up", self, "_host_lobby")

func _join_lobby():
	Network.join($LobbyList/Query.text)
	yield(Network, "client_joined")
	get_tree().change_scene("res://scenes/lobby.tscn")

func _host_lobby():
	Network.host()
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
