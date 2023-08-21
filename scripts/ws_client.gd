extends Node

export  var autojoin = true
export  var lobby = ""

var client:WebSocketClient = WebSocketClient.new()
var code = 1000
var reason = "Unknown"
var connected = false


var id = null
var inited = false
var username = ""
var lobby_genocided = false
var in_lobby = false
var lobby_id = null
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
signal ws_message(type, message)
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
	print("Socket Closed: %s" % was_clean)
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
	var data: String = client.get_peer(1).get_packet().get_string_from_utf8()
	var databits = data.split(":")
	var type = databits[0]
	databits.remove(0)
	var message = parse_json(databits.join(":"))
#	print(message)
	
	match type:
		"init":
			inited = true
			Network.ws_id = message.id

	emit_signal("ws_message", type, message)

func basesend(string)->int:
	if (connected):
		return client.get_peer(1).put_packet((string).to_utf8())
	else :
		return 24

func send(type: String, obj: Dictionary = {}):
	var send_string = to_json(obj)
	var send_data = (type+":"+send_string)
#	print(send_data)
	return basesend(send_data)

func ping():
	last_ping_time = Date.now()
	basesend("ping")

func get_avg_ping():
	pinging = true
	for i in ping_accu:
		ping()

func _physics_process(delta):
	var status:int = client.get_connection_status()
	if status == WebSocketClient.CONNECTION_CONNECTING or status == WebSocketClient.CONNECTION_CONNECTED:
		client.poll()
