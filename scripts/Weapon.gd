extends Area2D

const WEIGHT = 0.75
const explosion_obj = preload("res://objects/Explosion.tscn")

export  var COLOR = Color("#e03c28")
export  var angle = 0
export  var ext_motion = Vector2(0, 0)

onready var radius = $Shape.shape.radius
var id = ""
var husk
var age = 0
var off_screen_timer = 0
var inited = false
var spawner = null
var motion = Vector2(0, 0)
var last_positions = [position]

func spawn_explosion():
	var e_inst = explosion_obj.instance()
	e_inst.position = position
	e_inst.COLOR = COLOR
	e_inst.spawner = spawner
	e_inst.id = id
	GlobalVars.try_add_child("VP/EXPLOSIONS", e_inst)

func _ready():
	var speed = 20
	motion = (ext_motion / 100) + Vector2(cos(angle) * speed, sin(angle) * speed)

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

func _physics_process(delta):
	motion.y += WEIGHT
	
	position += motion
	
	for collider in get_overlapping_bodies():
		var allow = true
		
		if (collider == spawner):allow = false
		
		var is_above = was_above(collider.position.y)
		if (collider.is_in_group("Platform")):
			if not ((motion.y > 0) and is_above):
				allow = false
		if (allow):
			spawn_explosion()
			queue_free()
	
	last_positions.append(position)
