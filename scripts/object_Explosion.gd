extends Area2D

export  var COLOR = Color("#e03c28")

const w_id = 0

var id = null
var frame = 0
var spawner = null
var hit = []

func _ready():
	$Anim.connect("animation_finished", self, "kill")
	$Anim.play("Main")

func _process(delta):
	material.set_shader_param("PLAYER_COLOR", COLOR)
	material.set_shader_param("MOOD_COLOR", GlobalVars.mood_color)
	if (frame > 10):
		$Shape.disabled = true
	for collider in get_overlapping_bodies():
		if (collider.is_in_group("Player") and not hit.has(collider)):
			hit.append(collider)
			if (collider != spawner):
				collider.damage(60, {
					"attacker_username": spawner.username,
					"attacker_color": spawner.COLOR.to_html(false),
					"weapon_id": w_id,
					"sd": false
				})
	
	frame += 1

func kill(_kys):
	queue_free()
