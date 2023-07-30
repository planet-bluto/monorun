extends Node

export var loopWidth = 64 * 80
export var player_lives = 2
export var player_HP = 120
export var over_extend = 800

onready var root = get_parent()
onready var parent = root.get_node("VP")

var player_obj = preload("res://objects/Player.tscn")
var player_cam = preload("res://objects/PlayerCam.tscn")
var platform_obj = preload("res://objects/Platform.tscn")
var main_view_obj = preload("res://objects/MainViewRect.tscn")
var secondary_view_obj = preload("res://objects/SecondaryViewRect.tscn")
var client_player = null

var cam

func base_player_init(player_node, type, id, l_id = 0):
	player_node.type = type
	player_node.id = id
#	player_node.l_id = l_id
#	player_node.ping = ping
	player_node.MAX_HP = player_HP
	player_node.HP = player_node.MAX_HP
	player_node.MAX_LIVES = player_lives
	player_node.lives = player_node.MAX_LIVES
	if (type != 1 or not GlobalVars.temp_plr_info.has(id)):
		player_node.position = get_random_spawn_point()
	else :
		var temp_info = GlobalVars.temp_plr_info[id]
		player_node.position = temp_info.pos
		player_node.get_node("Anim").play(temp_info.anim)
		player_node.COLOR = GlobalVars.COLORS[temp_info.color]
		player_node.HP = temp_info.HP
	GlobalVars.try_add_child("VP/PLAYERS", player_node)
#	var doops = _loop_init(player_node)
#	if (type != 0):
#		for doop in doops:
#			doop.id = - 2
#			doop.type = 2
#			doop.position.y = - 640
#		_loop_append(player_node, doops)
	_init_conts(player_node)
	player_node.get_node("HP").visible = true
	player_node.connect("projectile", self, "_new_projectile")
	player_node.connect("died", self, "_player_death")

func _ready():
#	WsClient.normsend("IL", [player_HP, player_lives, false])
	yield (root, "ready")
	var tile_map = root.get_node("TileMap")
	var view_tile_map = tile_map.duplicate()
	parent.add_child_below_node(parent.get_node("PROJECTILES"), view_tile_map)
	for cell_vec in view_tile_map.get_used_cells_by_id(13):
		cell_vec *= 80
		var plat = platform_obj.instance()
		GlobalVars.try_add_child("VP/PLATFORMS", plat)
		plat.position = cell_vec + tile_map.position
	
	var left_tile_map = tile_map.duplicate()
	root.add_child_below_node(tile_map, left_tile_map)
	left_tile_map.position.x -= loopWidth
	var right_tile_map = tile_map.duplicate()
	root.add_child_below_node(left_tile_map, right_tile_map)
	right_tile_map.position.x += loopWidth
	
	view_tile_map.visible = false
	tile_map.visible = true
	left_tile_map.visible = true
	right_tile_map.visible = true
	
	
	var main_view_rect = main_view_obj.instance()
	root.add_child_below_node(right_tile_map, main_view_rect)
	var left_view_rect = secondary_view_obj.instance()
	root.add_child_below_node(main_view_rect, left_view_rect)
	left_view_rect.rect_position.x -= loopWidth
	var right_view_rect = secondary_view_obj.instance()
	right_view_rect.rect_position.x += loopWidth
	root.add_child_below_node(main_view_rect, right_view_rect)
	
	parent.size = Vector2(loopWidth+(over_extend*2), 1280)
	main_view_rect.texture.viewport_path = parent.get_path()
	main_view_rect.rect_size = parent.size
	main_view_rect.rect_position.x = -over_extend
	left_view_rect.texture.viewport_path = parent.get_path()
	left_view_rect.rect_size = Vector2(loopWidth, 1280)
	right_view_rect.texture.viewport_path = parent.get_path()
	right_view_rect.rect_size = Vector2(loopWidth, 1280)
	
#	var loopings = get_tree().get_nodes_in_group("Looping")
#	for node in loopings:
#		_loop_append(node, _loop_init(node))
	
#	WsClient.connect("new_data", self, "_ws_data")
	var _1 = Network.connect("peer_join", self, "init_net_player")
	var _2 = Network.connect("server_close", get_tree(), "change_scene", ["res://scenes/multiplayer.tscn"])
	var _3 = Network.connect("peer_leave", self, "player_leave")
	
	client_player = player_obj.instance()
	if Network.active: Network.id = get_tree().get_network_unique_id()
	base_player_init(client_player, 0, Network.id)
	
	cam = player_cam.instance()
	root.add_child(cam)
	client_player.get_node("Remote").remote_path = cam.get_path()
	cam.current = true
#	client_player.id = Network.id
	
#	var other_l_id = 1
#	for player in WsClient.players:
#		init_net_player(player.id, player.ping, other_l_id)
#		other_l_id += 1

func get_spawn_points():
	var spawn_points = []
	for spawn_point in get_tree().current_scene.get_node("SPAWNPOINTS").get_children():
		spawn_points.append(spawn_point.global_position)
	return spawn_points

func get_random_spawn_point():
	var spawn_points = get_spawn_points()
	randomize()
	spawn_points.shuffle()
	return spawn_points[0]

func _new_projectile(proj):
	pass
#	var doops = _loop_init(proj)
#	for doop in doops:
#		doop.id = proj.id
#		doop.spawner = proj.spawner
#	_loop_append(proj, doops)

func _player_death(player, respawn):
	if (respawn):
		yield (get_tree().create_timer(3.0), "timeout")
		if (player.type == 0):
			player.position = get_random_spawn_point()
		yield (get_tree().create_timer((WsClient.h_ping / 1000.0)), "timeout")
		player.spawn_self()

func _init_conts(player_obj):
	var PLAYER_CONT = Node2D.new()
	var TRAIL_CONT = Node2D.new()
	player_obj.emit_signal("trail_cont", TRAIL_CONT)
	PLAYER_CONT.add_child(TRAIL_CONT)
	PLAYER_CONT.material = player_obj.material
	TRAIL_CONT.use_parent_material = true
	GlobalVars.try_add_child("VP/PLAYER_CONTS", PLAYER_CONT)


#var loopnodes = {}

#func _loop_init(node):
#	if (loopWidth == - 1):
#		return []
#	else :
#		loopnodes[node] = {}
#		loopnodes[node].loopL = node.duplicate()
#		loopnodes[node].loopR = node.duplicate()
#		return [loopnodes[node].loopL, loopnodes[node].loopR]
#
#func _loop_append(node, doops):
#	for doop in doops:
#		var node_parent = node.get_parent()
#		node_parent.add_child_below_node(node, doop)

func get_player(search_id):
	var players = get_tree().get_nodes_in_group("Player")
	var return_player = null
	for player in players:
		if (str(player.id) == str(search_id)):
			return_player = player
	return return_player

remotesync func init_net_player(id, echo = false):
	var other_plr = player_obj.instance()
	base_player_init(other_plr, 1, id)
	other_plr.type = 1
	other_plr.id = id
	
	if (not echo): rpc_id(id, "init_net_player", Network.id, true)

#func _ws_data(type, args):
#
#	var player = null
#	var time_sent = null
#	var time_since = null
#	if (type.begins_with("in")):
#		type = type.substr(2, 1)
#		player = get_player(args[0])
#		time_sent = MonoBase.toDec(args.back())
#		time_since = (Date.now() - time_sent)
#		yield (OneShotTimer.start((WsClient.h_ping - time_since) / 1000.0), "timeout")
#	match type:
#
#
#
#		"J":
#			var player_vals = Array(args[0].split("|"))
#			print("%s joined..." % player_vals[0])
#			init_net_player(player_vals[1], float(player_vals[2]), (WsClient.players.size() + 1))
#		"F":
#			var fromDir = {"L":true, "R":false}
#			var sprite_dir = args[1]
#			player.get_node("Sprite").flip_h = fromDir[sprite_dir]
#			if (loopWidth != - 1):
#				loopnodes[player].loopL.get_node("Sprite").flip_h = fromDir[sprite_dir]
#				loopnodes[player].loopR.get_node("Sprite").flip_h = fromDir[sprite_dir]
#		"P":
#
#
#
#			var pos = Vector2(float(args[1]), float(args[2]))
#			player.position = pos
#		"A":
#			player.get_node("Anim").play(args[1])
#			if (loopWidth != - 1):
#				loopnodes[player].loopL.get_node("Anim").play(args[1])
#				loopnodes[player].loopR.get_node("Anim").play(args[1])
#
#
#		"W":
#			player.motion = Vector2(float(args[3]), float(args[4]))
#			player.spawn_proj(int(args[1]), float(args[2]), Vector2(float(args[5]), float(args[6])), int(args[7]))
#		"D":
#			player = get_player(args[0])
#			if (args[1] == "DIE"):
#				player.damage(player.MAX_HP)
#			else :
#				player.damage(int(args[1]))
#		"RQ":
#			player = get_player(args[0])
#			var ind = player.l_id
#			print("%s RAGEQUIT, LMAO" % WsClient.players[player.l_id].nick)
#			WsClient.players.remove(ind)
#			player.queue_free()

func repeat_check(node):
	if (node.position.x > loopWidth):
		node.position.x = 0
	if (node.position.x < 0):
		node.position.x = loopWidth

func _process(delta):
	parent.get_node("Cam").make_current()
	if (cam != null):
		for hud_elem in get_tree().get_nodes_in_group("HUD"):
			hud_elem.position = cam.get_camera_screen_center() + Vector2(80, 360)

func _physics_process(delta):
	var loopnodes = get_tree().get_nodes_in_group("Looping")
	
	if (loopWidth != - 1):
		for node in loopnodes:
#			print(node)
			repeat_check(node)
		
	
#		repeat_check(client_player)
