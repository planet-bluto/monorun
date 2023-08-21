extends Node

const MOODS = [
	"000000", 
	"151515", 
	"0d2030", 
	"231712", 
	"211640", 
	"172808", 
]

#const COLORS = [Color(0.878431, 0.235294, 0.156863), Color(0.00784314, 0.290196, 0.792157), Color(0.12549, 0.709804, 0.384314), Color(0.415686, 0.705882, 0.0901961), Color(1, 0.733333, 0.192157), Color(0.239216, 0.203922, 0.647059), Color(0.964706, 0.560784, 0.215686), Color(1, 0, 0.34902), Color(1, 0.509804, 0.807843), Color(0.443137, 0.65098, 0.631373), Color(0.415686, 0.192157, 0.792157), Color(0.682353, 0.423529, 0.215686), Color(0.0392157, 0.537255, 1), Color(0.482353, 0.482353, 0.482353), Color(0, 0, 0)]
const COLORS = [
	Color("#e03c28"),
	Color("#024aca"),
	Color("#52de98"),
	Color("#6bb814"),
	Color("#ffe433"),
	Color("#00ff00"),
	Color("#f68f37"),
	Color("#ff1998"),
	Color("#ffadcb"),
	Color("#10778f"),
	Color("#6a31ca"),
	Color("#a65d26"),
	Color("#0a89ff"),
	Color("#7b7b7b")
]

var temp_plr_info = []

export  var mood_color = Color(MOODS[0])
var current_camera = null

const WS_SERVER = "wss://monorunserverlist.donovanedwards.repl.co"

onready var tree = get_tree()

func _ready():
	var rng = RandomNumberGenerator.new()
	rng.randomize()


	mood_color = Color(MOODS[0])


var mouse_locked = false

func _process(delta):
#	pass
	if (Input.is_action_just_pressed("TOGGLE_MOUSE")):
		mouse_locked = ( not mouse_locked)
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED if mouse_locked else Input.MOUSE_MODE_VISIBLE)

func try_add_child(target_node, inst):
	if (get_tree().current_scene.has_node(target_node)):
		get_tree().current_scene.get_node(target_node).add_child(inst)
	else :
		print("No '%s' node" % target_node)
		get_tree().current_scene.add_child(inst)

func make_secondary(player, s_type):
	var Classes = [
		DashSecondary
	]
	
	var new_class = Classes[s_type].new(player)
	player.add_child(new_class)
	
	return new_class

func current_crosshair():
	var crosshairs = get_tree().get_nodes_in_group("Crosshair")
	if (crosshairs.size() > 0):
		return crosshairs[0]
	else:
		return null
