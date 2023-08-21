extends KinematicBody2D

const w_id = 1
const LITE_WEIGHT = 0.75
const WEIGHT = 40
const TERM_VELOCITY = 1300
var SPEED = 1300

export  var COLOR = Color("#e03c28")
export  var angle = 0
export  var ext_motion = Vector2(0, 0)

onready var radius = $Area2D/Shape.shape.radius
var NET_OBJ = false
var id = ""
var husk
var age = 0
var off_screen_timer = 0
var inited = false
var spawner = null
var motion = Vector2(0, 0)
var last_positions = [position]
var this_normal = Vector2.UP
var dir = "R"
var dir_mult = 1

var hit_plrs = []

const synced_vars = [
	"position",
	"COLOR"
]
puppet var weapon_state = {}

enum STATES {FALL, ROLL}
var state = STATES.FALL

func _init():
	for key in synced_vars:
		weapon_state[key] = self[key]

func _send_vars():
	if (Network.active):
		for key in synced_vars:
			weapon_state[key] = self[key]
		rset_unreliable("weapon_state", weapon_state)

func _set_vars():
	for key in synced_vars:
		self[key] = weapon_state[key]

#remote func spawn_explosion():
#	var e_inst = explosion_obj.instance()
#	e_inst.position = position
#	e_inst.COLOR = COLOR
#	e_inst.spawner = spawner
#	e_inst.id = id
#	GlobalVars.try_add_child("VP/EXPLOSIONS", e_inst)

func _ready():
	material = material.duplicate(true)
	name = "SAW"+id
	var speed = SPEED
	motion = ext_motion + Vector2(cos(angle) * speed, sin(angle) * speed)
	dir = spawner.sprite_dir
	$AnimationPlayer.play("main")
	$Spawn.play(0.0)

func _process(_delta):
	age += 1
	if (position.y > radius or position.y < - 1280 - radius):
		off_screen_timer += 1
		if (off_screen_timer > 300):
			queue_free()
	else :
		off_screen_timer = 0
	if (inited):
		material.set_shader_param("PLAYER_COLOR", COLOR)
		material.set_shader_param("MOOD_COLOR", GlobalVars.mood_color)

func was_above(y):
	var return_val = false
	for pos in last_positions:
		if (pos.y < y):
			return_val = true
	return return_val

var step_num = 0
func _physics_process(delta):
	dir_mult = (-1 if dir == "L" else 1)
	if (dir == "R"):
		$WallCasts/Left.enabled = false
		$UpWallCasts/Left.enabled = false
		$WallCasts/Right.enabled = true
		$UpWallCasts/Right.enabled = true
	else:
		$WallCasts/Left.enabled = true
		$UpWallCasts/Left.enabled = true
		$WallCasts/Right.enabled = false
		$UpWallCasts/Right.enabled = false
	
	$Sprite.flip_h = (dir == "L")
	if (not NET_OBJ):
		
		for collider in $Area2D.get_overlapping_bodies():
			if (collider.is_in_group("Player") and collider != spawner):
#				print("Kill this nigga btw %s" % collider)
				if (not hit_plrs.has(collider)):
					hit_plrs.append(collider)
					collider.damage(60, {
						"attacker_username": spawner.username,
						"attacker_color": spawner.COLOR.to_html(false),
						"weapon_id": w_id,
						"sd": false
					})
		
		match state:
			STATES.FALL:
				motion.y += WEIGHT
				motion.y = clamp(motion.y, -1300, 1300)
				var collision: KinematicCollision2D = get_last_slide_collision()
				if (collision != null):
					state = STATES.ROLL
					this_normal = collision.normal
					$Land.play(0.0)
					match this_normal:
						Vector2.UP:
							if ((motion.x > 0 and dir == "L") or ((motion.x < 0 and dir == "R"))):
								dir = ("L" if dir == "R" else "R")
						Vector2.DOWN:
							if ((motion.x > 0 and dir == "R") or ((motion.x < 0 and dir == "L"))):
								dir = ("L" if dir == "R" else "R")
						Vector2.LEFT:
							if (((motion.y > 0 and dir == "R") or (motion.y < 0 and dir == "L")) and ((abs(motion.x) - abs(motion.y*2)) < 100)):
								dir = ("L" if dir == "R" else "R")
						Vector2.RIGHT:
							if (((motion.y < 0 and dir == "R") or (motion.y > 0 and dir == "L")) and ((abs(motion.x) - abs(motion.y*2)) < 100)):
								dir = ("L" if dir == "R" else "R")
					motion.y = 1000
			STATES.ROLL:
#				print("ROLLING?")
				motion.x = SPEED*dir_mult
#				motion.y = 0
				
				var go_up_wall = false
				for _cast in $UpWallCasts.get_children():
					var cast: RayCast2D = _cast
					cast.force_raycast_update()
					if valid_cast(cast) and is_inv(cast):
						this_normal = cast.get_collision_normal()
						go_up_wall = true
						motion.x = 2400*dir_mult
						$Turn.play(0.0)
						break
				
				if (not go_up_wall):
					motion.x = SPEED*dir_mult
					var floored = false
					for cast in $FloorCasts.get_children():
						cast.collide_with_areas = false
						cast.collide_with_bodies = true
						if valid_cast(cast):
							floored = true 
							break
					
					if (not floored):
	#					print("> [%s] Not Floored" % step_num)
						for _cast in $WallCasts.get_children():
							var cast: RayCast2D = _cast
							cast.force_raycast_update()
							cast.collide_with_areas = false
							cast.collide_with_bodies = true
							var cast_normal = cast.get_collision_normal()
							if valid_cast(cast) and is_inv(cast):
								this_normal = cast.get_collision_normal()
								$Turn.play(0.0)
	#							print("> Cool, Change Normal")
								break
		
		rotation = atan2(this_normal.y, this_normal.x)+deg2rad(90)
#		motion.x = clamp(motion.x, -TERM_VELOCITY, TERM_VELOCITY)
#		motion.y = clamp(motion.y, -TERM_VELOCITY, TERM_VELOCITY)
		var final_motion = motion.rotated(rotation)
#		print(final_motion)
		move_and_slide(final_motion)
		last_positions.append(position)
		_send_vars()
	else:
		_set_vars()
	
	step_num += 1

func valid_cast(cast: RayCast2D):
	if (cast.is_colliding() and (cast.get_collider() != self) and (cast.get_collider() != $Area2D) and (not cast.get_collider().is_in_group("Player"))):
		if (cast.get_collider().is_in_group("Platform")):
			return (cast.get_collision_point().y >= cast.get_collider().position.y)
		else:
			return true
func is_inv(cast):
	var _1 = cast.cast_to.normalized().rotated(deg2rad(180)+cast.global_rotation).angle()
	var _2 = cast.get_collision_normal().angle()
	
#	print("\n\nInverse?")
#	print(  abs(_1)  )
#	print(  abs(_2)  )
#	print(  abs(abs(_1) - abs(_2))  )
#	print(  deg2rad(1.0)  )
#	print(  (abs(abs(_1) - abs(_2)) < deg2rad(1.0))   )
	
	return (abs(abs(_1) - abs(_2)) < deg2rad(1.0))

remote func kys(): queue_free()
