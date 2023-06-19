extends Node

signal hosting
signal client_joined
signal peer_join(id)
signal peer_leave(id)
signal server_close

const DEFAULT_PORT = 4887
const MAX_PEERS = 16

var peer = null
var id = null
var username = ""

var joined = false
var active = false

func _ready():
	var _1 = get_tree().connect("network_peer_connected", self, "_player_connected")
	var _2 = get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	var _3 = get_tree().connect("connected_to_server", self, "_connected_ok")
	var _4 = get_tree().connect("connection_failed", self, "_connected_fail")
	var _5 = get_tree().connect("server_disconnected", self, "_server_disconnected")

func host():
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(peer)
	print("Server hosted?")
	active = true
	emit_signal("hosting")

func join(ip):
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(peer)
	print("Joining?...")

func _connected_ok():
	print("Connected!")
	joined = true
	active = true
	emit_signal("client_joined")

func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	print("Naaawh, connection fail")
	active = false

func _player_connected(peer_id):
	print("New peer! (%s)" % peer_id)
	emit_signal("peer_join", peer_id)

func _player_disconnected(peer_id):
	print("Bye peer... (%s)" % peer_id)
	emit_signal("peer_leave", peer_id)

func _server_disconnected():
	print("server closed")
	active = false
	emit_signal("server_close")
