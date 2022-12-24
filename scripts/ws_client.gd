extends Node

export var autojoin = true
export var lobby = "" # Will create a new lobby if empty.

var client: WebSocketClient = WebSocketClient.new()
var code = 1000
var reason = "Unknown"
var connected = false

# MY VARS
var id = null
var username = ""
var lobby_id = null
var ping = 35
var pinging = false
var ping_time = -1

var players = []

signal lobby_joined(lobby)
signal connected(id)
signal disconnected()
signal peer_connected(id)
signal peer_disconnected(id)
signal offer_received(id, offer)
signal answer_received(id, answer)
signal candidate_received(id, mid, index, sdp)
signal lobby_sealed()
signal new_data(msg)
signal ws_connect()

func _init():
	client.connect("data_received", self, "_parse_msg")
	client.connect("connection_established", self, "_connected")
	client.connect("connection_closed", self, "_closed")
	client.connect("connection_error", self, "_closed")
	client.connect("server_close_request", self, "_close_request")

func connect_to_url(url):
	close()
	code = 1000
	reason = "Unknown"
	client.connect_to_url(url)

func close():
	client.disconnect_from_host()

func _closed(was_clean = false):
	emit_signal("disconnected")
	connected = false

func _close_request(code, reason):
	self.code = code
	self.reason = reason

func _connected(protocol = ""):
	client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	emit_signal("ws_connect")
	print("Socket Connected!")
	connected = true

func _parse_msg():
	var pkt_str: String = client.get_peer(1).get_packet().get_string_from_utf8()
#	emit_signal("new_data", pkt_str)
	var index = pkt_str.split(":")
	var index_type = index[0]
	index.remove(0)
	var args = []
	if (index.size() > 0):
		args = Array(index[0].split(","))
	emit_signal("new_data", index_type, args)
	match index_type:
		"I":
			id = args[0]
			send("SL")
		"Pong":
			pinging = false
			ping = (Time.get_unix_time_from_system()*1000) - ping_time
			print("Ping: %s" % ping)

func send(string) -> int:
	if (connected):
		return client.get_peer(1).put_packet((string).to_utf8())
	else:
		return 24

func send_candidate(id, mid, index, sdp) -> int:
	return send("C:%s\n%s\n%d\n%s" % [id, mid, index, sdp])

func ping():
	pinging = true
	send("Ping:")

func _physics_process(delta):
	var status: int = client.get_connection_status()
#	if (!pinging and connected):
#		ping_time = Time.get_unix_time_from_system()*1000
#		ping()
	if status == WebSocketClient.CONNECTION_CONNECTING or status == WebSocketClient.CONNECTION_CONNECTED:
		client.poll()
