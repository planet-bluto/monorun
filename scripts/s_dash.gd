extends Node
class_name DashSecondary

var DASH_SPEED = 1200.0
const DASH_DURATION = 0.2

var this_player
var tween = Tween.new()
var val = 1
var dash_ang = 0
var this_dashing = false

func _init(plr):
	this_player = plr

func _ready():
	add_child(tween)
	
	tween.connect("tween_completed", self, "_stop")

func exec():
	if (not this_dashing):
		dash_ang = this_player.get_aim_angle()
		this_player.physics_overhaul = true
		this_player.dashing = true
		this_player.MAX_DASH = DASH_SPEED
		
		tween.interpolate_property(self, "DASH_SPEED",
			2400.0, 1200.0, DASH_DURATION,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		
		tween.start()
#		print("STARTING")
		this_dashing = true

func _stop(obj = null, key = null):
#	print("STOPPING")
	this_player.MAX_DASH = 1200.0
	this_dashing = false
	this_player.physics_overhaul = false

func _physics_process(delta):
	if (this_dashing):
		this_player.motion = Vector2(cos(dash_ang) * (DASH_SPEED), sin(dash_ang) * (DASH_SPEED))
		var collide = this_player.get_last_slide_collision()
		
		if (collide != null):
			var collide_normal = collide.normal
			var dash_vec = Vector2(cos(dash_ang), sin(dash_ang))
			for axis in ["x", "y"]:
#				print("%s VS %s" % [dash_vec[axis], collide_normal[axis]])
#				print("%s" % dash_vec[axis] != "0")
#				print(dash_vec[axis] != collide_normal[axis])
#				print(collide_normal[axis] != 0.0)
				if (("%s" % dash_vec[axis] != "0") and (dash_vec[axis] != collide_normal[axis]) and (float(collide_normal[axis]) != float(0))):
					tween.stop_all()
					_stop()
					break
