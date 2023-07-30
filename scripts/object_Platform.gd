extends StaticBody2D

var down_time = 0
var off_time = 0

func _process(delta):
	if (Input.is_action_just_pressed("D")):
		if (down_time == 0):
			down_time = 15
		else :
			down_time = 0
			off_time = 7
	
	$Shape.disabled = (off_time > 0)
	
	if (down_time > 0):down_time -= 1
	if (off_time > 0):off_time -= 1
