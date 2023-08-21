extends HBoxContainer

onready var attacker_label = $Attacker
onready var username_label = $Username
onready var weapon_nodes = [
	$Bomb,
	$Saw
]
onready var tween: Tween = $Tween

var fade_out = 1
var pending_from_init = {}

func init(attacker, attacker_color, username, user_color, weapon_id):
	pending_from_init = {
		"attacker": attacker,
		"attacker_color": attacker_color,
		"username": username,
		"user_color": user_color,
		"weapon_id": weapon_id
	}

func _ready():
	var attacker = pending_from_init.attacker
	var attacker_color = pending_from_init.attacker_color
	var username = pending_from_init.username
	var user_color = pending_from_init.user_color
	var weapon_id = pending_from_init.weapon_id
	
	attacker_label.text = attacker
	attacker_label.add_color_override("font_color", attacker_color)
	username_label.text = username
	username_label.add_color_override("font_color", user_color)
	
	for weapon_node in weapon_nodes: weapon_node.visible = false
	if (weapon_id != -1): weapon_nodes[weapon_id].visible = true
	material.set_shader_param("PLAYER_COLOR", attacker_color)
	
	tween.interpolate_property(self, "fade_out",
		0, 1, 7,
		Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	tween.start()
	tween.connect("tween_completed", self, "_die_now")

func _process(delta):
	modulate = Color(1,1,1,(1-fade_out))

func _die_now(object, key):
	queue_free()
