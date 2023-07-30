extends Node2D

const player_shad = preload("res://misc/player_shader.tres")

var player_colors = GlobalVars.COLORS
var panel = true
var panel_val = 1.0
var hover_panel_button = false

func _ready():
	var o_i = 0
	for option in $FRONTHUD/Panel/ColorSelect.get_children():
		option.material = ShaderMaterial.new()
		option.material.shader = player_shad.duplicate()
		option.connect("pressed", self, "try_color", [o_i])
		o_i += 1
	WsClient.connect("new_data", self, "_ws_data")
	$FRONTHUD/Panel/PanelArrow.connect("pressed", self, "_toggle_panel")
	$FRONTHUD/Panel/PanelArrow.connect("mouse_entered", self, "_toggle_panel_btn_hover", [true])
	$FRONTHUD/Panel/PanelArrow.connect("mouse_exited", self, "_toggle_panel_btn_hover", [false])
	$FRONTHUD/Title.text = ("nothin.." if WsClient.lobby_title == null else WsClient.lobby_title)
	

func try_color(ind):
	$IngameWorker.client_player.COLOR = player_colors[ind]

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
	$FRONTHUD/Title.rect_position.x = - 720 + abs( - 122.5 * panel_val)
	if ($IngameWorker.client_player != null):
		if (panel or hover_panel_button):$IngameWorker.client_player.w_cooldown = 2
		$IngameWorker.cam.offset.x = - 122.5 * panel_val
		
		$FRONTHUD/Panel/WeaponSelect.material.set_shader_param("PLAYER_COLOR", $IngameWorker.client_player.COLOR)
		$FRONTHUD/Panel/ModSelect.material.set_shader_param("PLAYER_COLOR", $IngameWorker.client_player.COLOR)
	
	var vol_max = 20
	$PanelMusic.volume_db = (panel_val * vol_max) - vol_max
	$PlaytestMusic.volume_db = panel_val * - vol_max
	
	var o_i = 0
	for option in $FRONTHUD/Panel/ColorSelect.get_children():
		option.material.set_shader_param("PLAYER_COLOR", player_colors[o_i])
		o_i += 1
	
	material.set_shader_param("MOOD_COLOR", GlobalVars.mood_color)
	$BACKHUD/Background.color = GlobalVars.mood_color
	
	$Crosshair.position = get_global_mouse_position()

func _ws_data(type, args):
	match type:
		"C":
			$IngameWorker.get_player(args[0]).COLOR = player_colors[int(args[1])]
