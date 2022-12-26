extends Node2D

export var mood_color_override = Color(0,0,0)
var player_obj = preload("res://objects/Player.tscn")

var client_player = null

func _init_conts(player_obj):
	var PLAYER_CONT = Node2D.new()
	var TRAIL_CONT = Node2D.new()
	player_obj.emit_signal("trail_cont", TRAIL_CONT)
	PLAYER_CONT.add_child(TRAIL_CONT)
	PLAYER_CONT.material = player_obj.material
	TRAIL_CONT.use_parent_material = true
	add_child_below_node($Label, PLAYER_CONT)

func get_player(search_id):
	var players = get_tree().get_nodes_in_group("Player")
	var return_player = null
	for player in players:
		if (str(player.id) == str(search_id)):
			return_player = player
	return return_player

var loopnodes = {}

func _loop_init(node):
	loopnodes[node] = {}
	loopnodes[node].loopL = node.duplicate()
	loopnodes[node].loopR = node.duplicate()
	return [loopnodes[node].loopL, loopnodes[node].loopR]

func _loop_append(doops):
	for doop in doops:
		add_child(doop)

func init_net_player(id, ping = 0):
	var other_plr = player_obj.instance()
	other_plr.type = 1
	other_plr.id = id
	other_plr.ping = ping
	add_child(other_plr)
	var doops = _loop_init(other_plr)
	for doop in doops:
		doop.id = -2
		doop.type = 2
		doop.position.y = -640
	_loop_append(doops)
	_init_conts(other_plr)

func _ready():
	var loopings = get_tree().get_nodes_in_group("Looping")
	for node in loopings:
		_loop_append(_loop_init(node))

	WsClient.connect("new_data", self, "_ws_data")
#	GlobalVars.mood_color = mood_color_override
	print(WsClient.connected)
#	if (!WsClient.connected):
	client_player = player_obj.instance()
	client_player.type = 0
	client_player.position.y = -640
	add_child(client_player)
	_init_conts(client_player)
	
	for player in WsClient.players:
		init_net_player(player.id, player.ping)
	
#	var players = get_tree().get_nodes_in_group("Player")
#	print(players)
#	for player in players:
#		var PLAYER_CONT = Node2D.new()
#		var TRAIL_CONT = Node2D.new()
#		player.emit_signal("trail_cont", TRAIL_CONT)
#		PLAYER_CONT.add_child(TRAIL_CONT)
#		PLAYER_CONT.material = player.material
#		TRAIL_CONT.use_parent_material = true
#		add_child_below_node($Label, PLAYER_CONT)

func _ws_connected():
	add_line("CONNECTED!")

var last_msgs = {}
var flick_prevention = 20

func push_msg(type, since, sent):
	if (!last_msgs.has(type)):
		last_msgs[type] = []
	last_msgs[type].append({"since": since, "sent": sent})
	if (last_msgs[type].size() > flick_prevention):
		last_msgs[type].remove(0)

func time_check(type, sent):
	var has_type = last_msgs.has(type)
	var on_time = null
	if (!has_type):
		print("Making type: '%s'" % type)
	else:
		on_time = last_msgs[type].back().sent < sent
		if (!on_time):
			print("Message too late to be considered: %sms" % (sent - last_msgs[type].back().sent))
	return (!has_type or on_time)

func _ws_data(type, args):
#	add_line(msg)
	match type:
		"i":
			var player = get_player(args[0])
			var time_sent = MonoBase.toDec(args[2])
			var time_since = (Date.now() - time_sent)
			yield(OneShotTimer.start((player.ping - time_since)/1000.0), "timeout")
			GlobalInputManager.managers[str(args[0])].decode(args[1])
		"J":
			var player_vals = Array(args[0].split("|"))
			print("%s joined..." % player_vals[0])
			init_net_player(player_vals[1], float(player_vals[2]))
		"F":
			var fromDir = {"L": true, "R": false}
			var player = get_player(args[0])
			var time_sent = MonoBase.toDec(args[2])
			var time_since = (Date.now() - time_sent)
			yield(OneShotTimer.start((player.ping - time_since)/1000.0), "timeout")
			var sprite_dir = args[1]
			player.get_node("Sprite").flip_h = fromDir[sprite_dir]
			loopnodes[player].loopL.get_node("Sprite").flip_h = fromDir[sprite_dir]
			loopnodes[player].loopR.get_node("Sprite").flip_h = fromDir[sprite_dir]
		"P":
			var player = get_player(args[0])
			var time_sent = MonoBase.toDec(args[3])
			var time_since = (Date.now() - time_sent)
			if (time_check(type, time_sent)):
				push_msg(type, time_since, time_sent)
				yield(OneShotTimer.start((player.ping - time_since)/1000.0), "timeout")
				var pos = Vector2(float(args[1]), float(args[2]))
				player.position = pos
		"A":
			var player = get_player(args[0])
			var time_sent = MonoBase.toDec(args[2])
			var time_since = (Date.now() - time_sent)
			yield(OneShotTimer.start((player.ping - time_since)/1000.0), "timeout")
			player.get_node("Anim").play(args[1])
			loopnodes[player].loopL.get_node("Anim").play(args[1])
			loopnodes[player].loopR.get_node("Anim").play(args[1])
#			player.get_node("Camera").current = true
#			GlobalVars.current_camera = player.get_node("Camera")

func _process(delta):
	var stageWidth = 64*80
	for node in loopnodes:
#		pass
		loopnodes[node].loopL.position.x = node.position.x - stageWidth
		loopnodes[node].loopL.position.y = node.position.y
		loopnodes[node].loopR.position.x = node.position.x + stageWidth
		loopnodes[node].loopR.position.y = node.position.y
	
#	print("%s | %s | %s" % [-(stageWidth/2), client_player.position.x, (stageWidth/2)])
	if (client_player.position.x > (stageWidth/2)):
		client_player.position.x = -(stageWidth/2)
	if (client_player.position.x < -(stageWidth/2)):
		client_player.position.x = (stageWidth/2)
	
	material.set_shader_param("MOOD_COLOR", GlobalVars.mood_color)
	$Background.color = GlobalVars.mood_color
	
	$Crosshair.position = get_global_mouse_position()

func add_line(text):
	var lines = $Label.get_line_count()
	if (lines == 11):
		var textArr = $Label.text.split("\n")
		textArr.remove(0)
		$Label.text = textArr.join("\n")
	if ($Label.text == ""):
		$Label.text += text
	else:
		$Label.text += "\n"+text
