extends Node2D

export  var mood_color_override = Color(0, 0, 0)

func _ready():
	WsClient.connect("new_data", self, "_ws_data")

	print(WsClient.connected)

func _ws_connected():
	add_line("CONNECTED!")

var last_msgs = {}
var flick_prevention = 20

func push_msg(type, since, sent):
	if ( not last_msgs.has(type)):
		last_msgs[type] = []
	last_msgs[type].append({"since":since, "sent":sent})
	if (last_msgs[type].size() > flick_prevention):
		last_msgs[type].remove(0)

func time_check(type, sent):
	var has_type = last_msgs.has(type)
	var on_time = null
	if ( not has_type):
		print("Making type: '%s'" % type)
	else :
		on_time = last_msgs[type].back().sent < sent
		if ( not on_time):
			print("Message too late to be considered: %sms" % (sent - last_msgs[type].back().sent))
	return ( not has_type or on_time)

func _process(delta):
	material.set_shader_param("MOOD_COLOR", GlobalVars.mood_color)
	$Background.color = GlobalVars.mood_color
	
	$Crosshair.position = get_global_mouse_position()

func add_line(text):
	var lines = $VP/Label.get_line_count()
	if (lines == 11):
		var textArr = $VP/Label.text.split("\n")
		textArr.remove(0)
		$VP/Label.text = textArr.join("\n")
	if ($VP/Label.text == ""):
		$VP/Label.text += text
	else :
		$VP/Label.text += "\n" + text
