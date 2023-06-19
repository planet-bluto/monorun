extends Node
class_name Looper

export var stage_width = 5120

var loopnodes = {}

onready var root = get_tree().current_scene

#func _ready():

func _physics_process(_delta):
	var loopings = get_tree().get_nodes_in_group("Looping")
	for node in loopings:
		if (not loopnodes.has(node)):
			var doops = init(node)
			append(doops)
	
	for node in loopnodes:
		if (not is_instance_valid(node) or node.is_queued_for_deletion()):
			loopnodes[node].loopL.queue_free()
			loopnodes[node].loopR.queue_free()
			loopnodes.erase(node)
		else:
			loopnodes[node].loopL.position.x = node.position.x - stage_width
			loopnodes[node].loopL.position.y = node.position.y
			loopnodes[node].loopR.position.x = node.position.x + stage_width
			loopnodes[node].loopR.position.y = node.position.y
			if (GlobalVars.properties(node).has("looped_vars")):
				for key in node.looped_vars:
					loopnodes[node].loopL[key] = node[key]
					loopnodes[node].loopR[key] = node[key]
		
			if (node.position.x > (stage_width/2)):
				node.position.x = -(stage_width/2)
			if (node.position.x < -(stage_width/2)):
				node.position.x = (stage_width/2)

func init(node, flags = 15):
	loopnodes[node] = {}
	loopnodes[node].loopL = node.duplicate(flags)
	loopnodes[node].loopL.remove_from_group("Looping")
	loopnodes[node].loopL.position.x = node.position.x - stage_width
	loopnodes[node].loopR = node.duplicate(flags)
	loopnodes[node].loopR.remove_from_group("Looping")
	loopnodes[node].loopR.position.x = node.position.x + stage_width
	return {"node": node, "doops": [loopnodes[node].loopL, loopnodes[node].loopR]}

func append(init_info):
	var doops = init_info.doops
	var node = init_info.node
	for doop in doops:
		var node_parent = node.get_parent()
		if (node_parent == null):
			yield(node, "tree_entered")
			node_parent = node.get_parent()
		node_parent.call_deferred("add_child_below_node", node, doop, true)
