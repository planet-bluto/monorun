extends Node

export  var autojoin = true
export  var lobby = ""

var client:WebSocketClient = WebSocketClient.new()
var code = 1000
var reason = "Unknown"
var connected = false


var id = null
var username = ""
var lobby_genocided = false
var in_lobby = false
var lobby_id = null
var lobby_title = null
var lobby_ingame = false
var pinging = false
var last_ping_time = - 1
var ping_times = []
var ping_accu = 50
var avg_ping = 0
var h_ping = 250

var temp_plr_info = {}
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
signal got_avg_ping(ping)

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
	print("Socket Connected!")
	connected = true
	emit_signal("ws_connect")

func avg(arr):
	var total = 0
	var amount = 0
	for num in arr:
		total += num
		amount += 1
	return total / amount

func _parse_msg():
	var pkt_str:String = client.get_peer(1).get_packet().get_string_from_utf8()

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
		"Pong":

			var this_ping = 250
			ping_times.append(this_ping)
			if (ping_times.size() == ping_accu):
				pinging = false
				avg_ping = ceil(avg(ping_times))
				print("Avg Ping: %s" % avg_ping)
				emit_signal("got_avg_ping")
				ping_times = []
		"genocide":
			print("LOBBY GENOCIDE")
			lobby_genocided = true
			in_lobby = false
			get_tree().change_scene("res://scenes/multiplayer.tscn")

func send(string)->int:
	if (connected):
		return client.get_peer(1).put_packet((string).to_utf8())
	else :
		return 24

func insend(index, args):
	args.append(Date.nowMono())
	var new_args = PoolStringArray()
	for arg in args:
		new_args.append(str(arg))
	var send_string = "in%s:%s" % [index, new_args.join(",")]
	return send(send_string)

func normsend(index, args, date = false):
	if (date):args.append(Date.nowMono())
	var new_args = PoolStringArray()
	for arg in args:
		new_args.append(str(arg))
	var send_string = "%s:%s" % [index, new_args.join(",")]
	return send(send_string)

func ping():
	last_ping_time = Date.now()
	send("Ping:")

func get_avg_ping():
	pinging = true
	for i in ping_accu:
		ping()

func _physics_process(delta):
	var status:int = client.get_connection_status()



	if status == WebSocketClient.CONNECTION_CONNECTING or status == WebSocketClient.CONNECTION_CONNECTED:
		client.poll()
