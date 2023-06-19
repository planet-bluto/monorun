extends Node2D

export var mood_color_override = Color(0,0,0)
var player_obj = preload("res://objects/Player.tscn")
var platform = preload("res://objects/platform.tscn")

var client_player = null

func _init_conts(plr: Player):
	var PLAYER_CONT = Node2D.new()
	var TRAIL_CONT = Node2D.new()
	plr.emit_signal("trail_cont", TRAIL_CONT)
	$Looper.loopnodes[plr].loopL.TRAIL_CONT = TRAIL_CONT
	$Looper.loopnodes[plr].loopR.TRAIL_CONT = TRAIL_CONT
	PLAYER_CONT.add_child(TRAIL_CONT)
	PLAYER_CONT.material = plr.material
	TRAIL_CONT.use_parent_material = true
	add_child_below_node($Label, PLAYER_CONT)

func get_player(search_id):
	var players = get_tree().get_nodes_in_group("Player")
	var return_player = null
	for player in players:
		if (str(player.id) == str(search_id)):
			return_player = player
	return return_player

func loop_player(plr: Player):
	var init_info = $Looper.init(plr, 4)
	var doops = init_info.doops
	for doop in doops:
		doop.id = -2
		doop.type = 2
		doop.TRAIL_CONT = plr.TRAIL_CONT
		doop.position.y = -640
	$Looper.append(init_info)

remotesync func init_net_player(id, echo = false):
	var other_plr = player_obj.instance()
	other_plr.type = 1
	other_plr.id = id
#	other_plr.ping = ping
	loop_player(other_plr)
	add_child(other_plr)
	_init_conts(other_plr)
	
	if (not echo): rpc_id(id, "init_net_player", Network.id, true)

func _ready():
	var _1 = Network.connect("peer_join", self, "init_net_player")
	var _2 = Network.connect("server_close", get_tree(), "change_scene", ["res://scenes/multiplayer.tscn"])
	var _3 = Network.connect("peer_leave", self, "player_leave")
	client_player = player_obj.instance()
	client_player.type = 0
	client_player.position.y = -640
	if Network.active: Network.id = get_tree().get_network_unique_id()
	client_player.id = Network.id
	loop_player(client_player)
	add_child(client_player)
	_init_conts(client_player)
	
	for tile_pos in $TileMap.get_used_cells_by_id(13):
		var real_pos = (tile_pos*80)+$TileMap.position
		var plat_inst = platform.instance()
		plat_inst.position = real_pos
		$TileMap.add_child(plat_inst)

func player_leave(id):
	for player in get_tree().get_nodes_in_group("Player"):
		if (player.id == id): 
			print("fuck you die")
			player.queue_free()

func _process(_delta):
	material.set_shader_param("MOOD_COLOR", GlobalVars.mood_color)
	$Background.color = GlobalVars.mood_color

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
