extends Node2D

const STATES = {
	0: "input_name",
	1: "choose_lobby"
}

var STATE = 0
var LobbyTemplate = preload("res://objects/LobbyTemplate.tscn")

func _ready():
	WsClient.connect_to_url("wss://MonorunSignalingServer.donovanedwards.repl.co")
#	WsClient.connect_to_url("ws://localhost:2022/")
	WsClient.connect("ws_connect", self, "_ws_connected")
	WsClient.connect("new_data", self, "_ws_data")
	
	$LobbyList/HostButton.connect("button_up", self, "_host_lobby")

func _ws_connected():
	pass

func _ws_data(type, args):
#	print(args)
	match type:
		"SL":
			if (args[0] != ""):
				for rawlobby in args:
					var lobby = Array(rawlobby.split("|"))
					print(lobby)
					var temp = LobbyTemplate.instance()
					var title_label = temp.get_node("Title")
					title_label.text = lobby[0]
					var join_button = temp.get_node("JoinButton")
					join_button.connect("pressed", self, "_join_lobby", lobby)
					$LobbyList/Container.add_child(temp)
			else:
				pass
		"HL":
			print("Lobby created!")
			get_tree().change_scene("res://scenes/test.tscn")
		"L":
			print("Got lobby info!")
			print(args)
			
			for player_info in args:
				player_info = Array(player_info.split("|"))
#				GlobalVars.temp_plr_info.append({"id": player_info[1], "x": player_info[2], "y": player_info[3]})
				WsClient.players.append({"id": player_info[1], "nick": player_info[0], "ping": float(player_info[2])})
			
			get_tree().change_scene("res://scenes/test.tscn")

func _host_lobby():
	WsClient.send("HL:%s's Lobby"%[WsClient.username])

func _join_lobby(title, id):
	WsClient.send("J:%s,%s" % [id, WsClient.avg_ping])

func _process(_delta):
	material.set_shader_param("MOOD_COLOR", GlobalVars.mood_color)
	$Background.color = GlobalVars.mood_color
	$Crosshair.position = get_global_mouse_position()
	if (STATE == 0):
		if (Input.is_action_just_pressed("CONFIRM") and $PlayerInfo/Nickname.text.length() > 0) and !WsClient.pinging:
			WsClient.username = $PlayerInfo/Nickname.text
			WsClient.get_avg_ping()
			yield(WsClient, "got_avg_ping")
			WsClient.send("I:%s,%s" % [WsClient.username, WsClient.avg_ping])
			$PlayerInfo.visible = false
			$LobbyList.visible = true
