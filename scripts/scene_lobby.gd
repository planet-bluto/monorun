extends Node2D

const player_shad = preload("res://misc/player_shader.tres")

onready var background_node = $BACKHUD/Background
var player_colors = GlobalVars.COLORS
var panel = true
var panel_val = 1.0
var hover_panel_button = false

var player_color_arr = []
func _ready():
	var o_i = 0
	for option in $FRONTHUD/Panel/ColorSelect.get_children():
		player_color_arr.append(null)
		option.material = ShaderMaterial.new()
		option.material.shader = player_shad.duplicate()
		option.connect("pressed", self, "try_color", [o_i])
		o_i += 1
	$FRONTHUD/Panel/PanelArrow.connect("pressed", self, "_toggle_panel")
	$FRONTHUD/Panel/PanelArrow.connect("mouse_entered", self, "_toggle_panel_btn_hover", [true])
	$FRONTHUD/Panel/PanelArrow.connect("mouse_exited", self, "_toggle_panel_btn_hover", [false])
	if Network.active: $FRONTHUD/Title.text = ("nothin.." if Network.lobby.title == null else Network.lobby.title)
	$IngameWorker.connect("new_player", self, "_new_player")
	var w_id = 0
	for weapon_choice in $FRONTHUD/Panel/WeaponSelect.get_children():
		weapon_choice.connect("pressed", self, "_select_weapon", [w_id])
		w_id += 1
	var _3 = Network.connect("peer_leave", self, "_player_leave")

var weapon_choosing = false
func _select_weapon(w_id, RESET = false):
	var choices = $FRONTHUD/Panel/WeaponSelect.get_children()
	if (weapon_choosing or RESET):
		for choice in choices: choice.visible = false
		
		choices[w_id].visible = true
		weapon_choosing = false
		$IngameWorker.client_player.w_type = w_id
	else:
		for choice in choices: choice.visible = true
		weapon_choosing = true

func _new_player(node):
	if (node == $IngameWorker.client_player): _select_weapon(0, true)
	if (Network.id == 1):
		var new_ind = player_color_arr.find(null)
		print("heller??, %s, %s" % [node.id, new_ind])
		if (node.id != 1):
			print("Peer #%s channel opened: %s" % [node.id, Network.peer_connected(node.id)])
			if (not Network.peer_connected(node.id)): yield(Network.await_peer_connection(node.id), "completed")
			print("Peer #%s is cool now" % node.id)
			rpc("change_color", node.id, new_ind)
			rpc_id(node.id, "color_init", player_color_arr)
		else:
			change_color(node.id, new_ind)
#			color_init(player_color_arr)
	else:
		pass
#		var ind = player_color_arr.find(node.id)
#		change_color(node.id, ind)

func _player_leave(id):
	if (Network.id == 1):
		var ind = player_color_arr.find(id)
		rpc("free_color", ind)
		free_color(ind)

remote func free_color(ind):
	if (ind != -1):
		var old_color_node: Button = $FRONTHUD/Panel/ColorSelect.get_node("Color_%s" % ind)
		print("On: %s" % ind)
		old_color_node.disabled = false
		player_color_arr[ind] = null

remote func color_init(arr):
	prints("COLOR INIT !!", arr)
	player_color_arr = arr
	
	var o_i = 0
	for id in player_color_arr:
		if (id != null):
			change_color(id, o_i)
		o_i += 1

func try_color(ind):
	if (Network.id != 1):
#		print("ok...")
		rpc_id(1, "req_color_change", ind)
	else:
		req_color_change(ind, 1)

remote func req_color_change(ind, sender = null):
	if (sender == null):
		sender = get_tree().get_rpc_sender_id()
#	print("Color Change Request: %s" % ind)
	rpc("change_color", sender, ind)

remotesync func change_color(id, ind):
	var old_ind = player_color_arr.find(id)
	print("\n\n=== COLOR CHANGE===")
	print("ID: %s" % id)
	print("COLOR: %s" % ind)
	free_color(old_ind)
	
	if ($VP/PLAYERS.has_node("Player_%s" % id)): 
		$VP/PLAYERS.get_node("Player_%s" % id).COLOR = player_colors[ind]
	
		var color_node: Button = $FRONTHUD/Panel/ColorSelect.get_node("Color_%s" % ind)
		print("Off: %s" % ind)
		color_node.disabled = true
		player_color_arr[ind] = id
#	$IngameWorker.client_player.COLOR = player_colors[ind]

func _toggle_panel_btn_hover(state):
	hover_panel_button = state

func _toggle_panel():
	var tween = get_tree().create_tween()
	tween.set_parallel()

	tween.set_trans(Tween.TRANS_SINE)
	if panel:
		tween.tween_property($FRONTHUD/Panel, "position", Vector2( - 245.0, 0.0), 0.2)
		tween.tween_property(self, "panel_val", 0.0, 0.2)
	else :
		$IngameWorker.client_player.w_cooldown = 0
		tween.tween_property($FRONTHUD/Panel, "position", Vector2(0.0, 0.0), 0.2)
		tween.tween_property(self, "panel_val", 1.0, 0.2)
	panel = not panel
	tween.play()

func _process(delta):
	for button in $FRONTHUD/Panel/ColorSelect.get_children():
		button.release_focus()
	
#	$IngameWorker.cam.limit_left = 0
#	$IngameWorker.cam.limit_right = 1840
	$IngameWorker.cam.limit_top = 240
	$IngameWorker.cam.limit_bottom = 960
	
	if panel:
		$FRONTHUD/Panel/PanelArrow.rect_scale.x = 1
		$FRONTHUD/Panel/PanelArrow.rect_position.x = - 490
	else :
		$FRONTHUD/Panel/PanelArrow.rect_scale.x = - 1
		$FRONTHUD/Panel/PanelArrow.rect_position.x = - 425
	
	$FRONTHUD/Fade.modulate = Color(1, 1, 1, panel_val)
	$FRONTHUD/Title.rect_position.x = - 720 + abs( -120 * panel_val)
	if ($IngameWorker.client_player != null):
		if (panel or hover_panel_button):$IngameWorker.client_player.w_cooldown = 2
		$IngameWorker.cam.offset.x = -120 * panel_val
		
		$FRONTHUD/Panel/WeaponSelect.material.set_shader_param("PLAYER_COLOR", $IngameWorker.client_player.COLOR)
		$FRONTHUD/Panel/ModSelect.material.set_shader_param("PLAYER_COLOR", $IngameWorker.client_player.COLOR)
	
	var vol_max = 20
	$PanelMusic.volume_db = (panel_val * vol_max) - vol_max
	$PlaytestMusic.volume_db = panel_val * - vol_max
	
	var o_i = 0
	for option in $FRONTHUD/Panel/ColorSelect.get_children():
		option.material.set_shader_param("PLAYER_COLOR", player_colors[o_i])
		o_i += 1
