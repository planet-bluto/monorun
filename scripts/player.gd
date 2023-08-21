extends KinematicBody2D

signal trail_cont
signal projectile
signal died

export var type = 0
export var id: int = -1
export var username = ""
export var ping = 0
export var COLOR = Color("#e03c28")



export  var WEIGHT = 40
export  var FAST_FALL = 50
export  var MAX_FALL = 1200
export  var SPEED = 700
export  var DASH_SPEED = 1200
var MAX_DASH = DASH_SPEED
export  var ACCEL = 90
export  var JUMP = 1300
export  var FRICTION = 1.2
export  var DASH_FRICTION = 1.04

const UP = Vector2(0, - 1)

var last_attack_info = {}
var physics_overhaul = false
var motion = Vector2(0, 0)
var add_motion = Vector2(0, 0)
var w_motion = motion
var grounded = true
var ground_timer = 0
var bonk_timer_y = 0
var bonk_timer_x = 0
var free_timer = 0
var jump_pending = false
var jump_buffer = 0
var max_jumps = 1
var jumps = max_jumps
var dash_pending = false
var dashing = false
var dash_buffer = 0
var joy_dir = 0
var last_dir = 1
var trails = []
var trail_amount = 7
var btn_timer = {}
var wall_dir = 0
var wall_jumpable = false
var wall_jump_cooldown = false
var sprite_dir = "R"
var last_sprite_dir = sprite_dir
var last_pos = Vector2()
var curr_anim = ""
var last_anim = ""
var fastfalling = false
const synced_vars = [
	"position",
	"w_motion",
	"curr_anim",
	"sprite_dir",
	"fastfalling",
	"joy_dir",
	"dash_pending",
	"jump_pending",
	"HP",
#	"hitstun",
	"sprite_visible"
]
puppet var player_state = {}

var looped_vars = [
	"sprite_dir",
	"curr_anim"
]

func _init():
	for key in synced_vars:
		if (key == "sprite_visible"):
			player_state[key] = true
		else:
			player_state[key] = self[key]

var MAX_HP = 120
var MAX_LIVES = 2
var HP = MAX_HP
var prev_HP = HP
var hitstun = 0
var lives = MAX_LIVES
var dead = false
var final_death = false

var pit_id = 0



var proj_id = 0

const weapons = {
	0: {
		"obj":preload("res://objects/Bomb.tscn"), 
		"cooldown":40
	},
	1: {
		"obj":preload("res://objects/Saw.tscn"), 
		"cooldown":40
	},
}

export var w_type = 1
export var s_type = -1
onready var current_secondary = GlobalVars.make_secondary(self, s_type)

var w_cooldown = 0

var TRAIL_CONT = null
var VELOCITY = {
	"SPEED":0, 
	"ANGLE":0
}

var mouse_screen_pos = (get_global_mouse_position()-(OS.window_size/2.0))+global_position
var screen_pos = global_position

var Inputs

func spawn_self():
	$Sprite.visible = true
	dead = false
	HP = MAX_HP
	$HP / Bar.rect_size.x = 80
	w_cooldown = 0

func spawn_trail():
	if (TRAIL_CONT != null):
		var sprite = $Sprite.duplicate(8)
		TRAIL_CONT.add_child(sprite)
		sprite.position = (position + $Sprite.position)
		sprite.frame_coords = $Sprite.frame_coords
		var fade = 0.35
		var fade_time = 0.1
		var tween = Tween.new()
		sprite.add_child(tween)
		tween.interpolate_property(sprite, "modulate", Color(1, 1, 1, fade), Color(1, 1, 1, 0), fade_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()
		yield (get_tree().create_timer(fade_time), "timeout")
		sprite.queue_free()

remotesync func spawn_proj(w_type, angle, echo = true, this_proj_id = proj_id):
	if (weapons.has(w_type) and w_cooldown == 0):
		var weapon_obj = weapons[w_type].obj
		var w_inst = weapon_obj.instance()
		w_inst.angle = angle
		w_inst.id = "-%s_%s" % [this_proj_id, id]
		w_inst.spawner = self
		w_inst.position.x = position.x
		w_inst.position.y = position.y - 20
		w_inst.COLOR = COLOR
		w_inst.set_network_master(id)

		w_inst.ext_motion = w_motion
		GlobalVars.try_add_child("VP/PROJECTILES", w_inst)
		emit_signal("projectile", w_inst)
		w_cooldown = weapons[w_type].cooldown
		if (echo): rpc("spawn_proj", w_type, angle, false, proj_id)
		if (type == 0):
			proj_id += 1
		else: 
			w_inst.NET_OBJ = true
		w_inst.inited = true



remotesync func damage(amount, extra_info, echo = true):
	var valid = false
	
	if (echo == false):
		valid = true
	else:
		if (Network.rtc_connected):
			if (Network.id != id):
				if (echo): rpc("damage", amount, extra_info, false)
		else:
			valid = true
	
	if (HP != - 1 and hitstun == 0 and valid):
		last_attack_info = extra_info
		hitstun = 10
		HP -= amount
		HP = clamp(HP, 0, MAX_HP)
		
		if (HP == 0):
			die()

func die():
	if (not dead):
		if (lives != - 1):
			lives -= 1
			lives = clamp(lives, 0, MAX_LIVES)
			print("Player#%s lost a life: %s" % [id, lives])
		dead = true
		if (lives == 0):
			final_death = true
	#					$Camera.zoom = Vector2(8.91, 8.91)
			emit_signal("died", self, false)
		else :
			emit_signal("died", self, true)

func _ready():
	name = "Player_%s" % id
	if Network.active: set_network_master(id)
	print("id: %s" % id)
	print("type: %s" % type)
	Inputs = InputManager.new(type, id)
	Inputs.connect("pressed", self, "_input_press")
	Inputs.connect("released", self, "_input_release")
	
	if (type == 0):
#		$Camera.current = true
		GlobalVars.current_camera = $Camera
	material = material.duplicate(8)
	connect("trail_cont", self, "_got_trail_cont")
	
#	if ( not OS.is_debug_build() or false):
#		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

var last_aim_vec = Vector2(0, 0)
func get_aim_angle():
	var vert = 0
	var hori = 0
	
	var vert_test = (Inputs.timers["U"] != 0 or Inputs.timers["D"] != 0)
	var hori_test = (Inputs.timers["L"] != 0 or Inputs.timers["R"] != 0)
	
	if (hori_test or vert_test):
		if (vert_test):
			if (Inputs.timers["U"] == 0): vert = 1
			elif (Inputs.timers["D"] == 0): vert = -1
			elif (Inputs.timers["D"] < Inputs.timers["U"]): vert == 1
			elif (Inputs.timers["U"] < Inputs.timers["D"]): vert == -1
		if (hori_test):
			if (Inputs.timers["L"] == 0): hori = 1
			elif (Inputs.timers["R"] == 0): hori = -1
			elif (Inputs.timers["R"] < Inputs.timers["L"]): hori == 1
			elif (Inputs.timers["L"] < Inputs.timers["R"]): hori == -1
	else:
		vert = last_aim_vec.y
		hori = last_aim_vec.x
	
	last_aim_vec = Vector2(hori, vert)
#	return atan2(mouse_screen_pos.y - screen_pos.y+17, mouse_screen_pos.x - screen_pos.x)
	return atan2(vert, hori)

func _input_press(key):
	if ( not dead):
		if (key == "SHOOT"):
			var aim_angle = get_aim_angle()
			spawn_proj(w_type, aim_angle)
		if (key == "ALT"):
			current_secondary.exec()
		if (key == "R"):
			joy_dir = 1
		if (key == "L"):
			joy_dir = - 1
		if (key == "JUMP"):
			jump_pending = true
		if (key == "DASH"):
			dash_pending = true

func _input_release(key):
	if (key == "R"):
		if ( not Inputs.is_down("L")):
			joy_dir = 0
		else :
			joy_dir = - 1
	if (key == "L"):
		if ( not Inputs.is_down("R")):
			joy_dir = 0
		else :
			joy_dir = 1

func _got_trail_cont(trail_cont):
	TRAIL_CONT = trail_cont

#func send_pos():
#	if (type == 0):
#		var pos_x = position.x
#		var pos_y = position.y
#		WsClient.insend("P", [pos_x, pos_y])
#
#func send_anim():a
#		WsClient.insend("A", [curr_anim])

var mouse_lock = true
func _process(_delta):
	$Aimer.rotation = get_aim_angle()
	
#	if (Input.is_action_just_pressed("TOGGLE_MOUSE")): mouse_lock = !mouse_lock
	
#	if (mouse_lock and (not OS.is_debug_build())):
#		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
#	else:
#		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if (HP != prev_HP):
		var new_width = (float(HP) / float(MAX_HP)) * 80.0
		var tween = get_tree().create_tween()
		tween.set_parallel()
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property($HP / Bar, "rect_size", Vector2(new_width, $HP / Bar.rect_size.y), 0.2)
		tween.play()
	
	prev_HP = HP
	
	if (w_cooldown > 0):w_cooldown -= 1
	
	if (dead):
		$Sprite.visible = false
		motion = Vector2(0, 0)
	
	if (final_death and type == 0):
		position.x += 5
		position.y = - 160
	
	mouse_screen_pos = GlobalVars.current_crosshair().global_position
#	print(mouse_screen_pos)
	screen_pos = global_position
#	print("%s - %s" % [mouse_screen_pos, screen_pos])

	
	if (joy_dir != 0):
		last_dir = joy_dir
	
	
	
	
	if (VELOCITY.SPEED > 1000):
		spawn_trail()
	
	$HP / Bar.color = COLOR
	material.set_shader_param("PLAYER_COLOR", COLOR)
	material.set_shader_param("MOOD_COLOR", GlobalVars.mood_color)

func _send_vars():
	if (Network.rtc_connected):
		for key in synced_vars:
			if (key == "sprite_visible"):
				player_state[key] = $Sprite.visible
			else:
				player_state[key] = self[key]
#			print(player_state)
	#	print(player_state)
		rset_unreliable("player_state", player_state)

func _set_vars():
	if (Network.peer_connected(int(id))):
		for key in synced_vars:
			if (key == "sprite_visible"):
				$Sprite.visible = player_state[key]
			else:
				self[key] = player_state[key]

func _physics_process(_delta):
	hitstun -= (1 if hitstun > 0 else 0)
	if (hitstun != 0):
		modulate = Color(255,255,255,1)
	else:
		modulate = Color(1,1,1,1)
#	if (last_pos != position):
#		send_pos()
#	last_pos = position
	
	if (last_anim != curr_anim):
		$Anim.play(curr_anim)
#			send_anim()
	last_anim = curr_anim
	
	if (not dead):
		active_movement()
	
	if (type == 0):
		_send_vars()
	elif (type == 1): 
		_set_vars()

func active_movement():
	if ((position.y - 10) - 320 > 1280):
		last_attack_info = {"sd": true}
		die()
	
	var toDIR = {true: "L", false: "R"}
	var screen_width = OS.window_size.x
#	print(mouse_screen_pos)
	if (type == 0 and last_aim_vec.x != 0): sprite_dir = toDIR[(last_aim_vec.x < 0)]
	if (sprite_dir != last_sprite_dir):
		last_sprite_dir = sprite_dir
#			yield(OneShotTimer.start(0.001*WsClient.ping), "timeout")
		$Sprite.flip_h = (sprite_dir == "L")
	
	VELOCITY.SPEED = sqrt(pow(motion.x, 2) + pow(motion.y, 2))
	VELOCITY.ANGLE = atan2(motion.y, motion.x)
	grounded = (is_on_floor())
	
	if (not physics_overhaul):
		calc_movement()
	
	move_and_slide((motion + add_motion), UP, false, 4, 0)
	
	w_motion = motion
	
	update()

func calc_movement():
	if (grounded):
		jump_buffer = 5
		free_timer = 0
		ground_timer += 1
		jumps = max_jumps
	else :
		jump_buffer -= 1
		ground_timer = 0
		free_timer += 1
	
	if (is_on_ceiling()):
		bonk_timer_y += 1
		if (bonk_timer_y == 1):
			motion.y *= - 0.25
	else :
		bonk_timer_y = 0
	
	var collide = get_last_slide_collision()
	var ang = - 1
	if (collide != null):
		ang = rad2deg(atan2(collide.normal.y, collide.normal.x))
	
	if (is_on_wall()):
		bonk_timer_x += 1
		motion.x = 0
		
		if (not wall_jump_cooldown):
			motion.y = 200
		wall_dir = 1
		if (ang == 180):
			wall_dir = - 1
#		if ((wall_dir == - 1) == (not $Sprite.flip_h)):
#			motion.y = 200
	else :
		bonk_timer_x = 0
	
	# and ((wall_dir == - 1) == (not $Sprite.flip_h))
	
	if ((ang == 180 or ang == 0) and is_on_wall()):
		wall_jumpable = true
	else :
		wall_jumpable = false
	
	if (ground_timer == 1):
		motion.y = 0
	
	if (type == 0): fastfalling = Inputs.is_down("D")
	
	if ( not grounded):
		if (jumps > max_jumps - 1 and jump_buffer == 0):
			jumps = max_jumps - 1
		if (motion.y + WEIGHT > MAX_FALL):
			motion.y = MAX_FALL
		else :
			var curr_ff = 0
			if (fastfalling):
				curr_ff = FAST_FALL
			motion.y += (WEIGHT + curr_ff)
	
		if (motion.y < 0):
			if (motion.y > - 400):
				curr_anim = "jump_peak"
			else :
				curr_anim = "jump"
		else :
			curr_anim = "fall"
	
	if joy_dir != 0:
		var div = 2.3
		if (grounded):
			curr_anim = "run"
			div = 1
		motion.x += (ACCEL * joy_dir) / div

	else :
		if (grounded):
			curr_anim = "idle"
		var curr_fric = FRICTION
		if (dashing):
			curr_fric = DASH_FRICTION
		if ( not grounded):
			curr_fric = 1.009
		if (abs(motion.x) > 0.01):
			motion.x /= curr_fric
		else :
			motion.x = 0
	
	if (jump_pending):
		jump_pending = false
		if (wall_jumpable):
			motion.y = - JUMP * 0.9
			motion.x = (DASH_SPEED / 1.2) * wall_dir
#			sprite_dir = ("L" if sprite_dir == "R" else "R")
#			wall_jumpable = false
			wall_jump_cooldown = true
			yield(get_tree().create_timer(0.1), "timeout")
			wall_jump_cooldown = false
		if (jumps > 0):
			motion.y = - JUMP
			jumps -= 1
	
	if (dash_pending):
		dash_pending = false
		if (grounded):
			motion.x = (DASH_SPEED * last_dir)
			dashing = true
	
	if (abs(motion.x) < SPEED and grounded):
		dashing = false
		MAX_DASH = DASH_SPEED
	
	if (dashing):
		motion.x = clamp(motion.x, - MAX_DASH, MAX_DASH)
	else :
		motion.x = clamp(motion.x, - SPEED, SPEED)

func global_to_screen(vec2):
	var camera_pos = ($Camera.get_camera_screen_center())
	print($Camera.get_camera_screen_center())
	if (camera_pos != null):
		return camera_pos - vec2
	else :
		return null
