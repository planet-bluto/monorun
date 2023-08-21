extends Node

signal connected()
signal setup_completed()
signal peer_join( id )
signal peer_connected( id )
signal peer_leave( id )

const SIGNAL_SERVER = "wss://monorunsignallingserver.donovanedwards.repl.co"

var ws_client:WebSocketClient = WebSocketClient.new()
var rtc_mp: WebRTCMultiplayer = WebRTCMultiplayer.new()

# Private Technical Vars
var true_id = null
var connected = false
var rtc_connected = false
var awaiting_funcs = {}
var awaiting_peers = {}
var func_total = -1

# Public Lobby Vars
var id = null
var username = ""
var lobby = null
var active = false
var connected_peers = []

#### FOREGROUND FUNCTIONS ####

func start():
#	close()
	active = true
	print("Socket Connecting...")
	ws_client.connect_to_url(SIGNAL_SERVER)

func emit(type, res = []):
	func_total += 1
	var func_id = func_total
	var state = _emit(type, func_id, res)
	awaiting_funcs[func_id] = state
	return state

var awaiting_clients = {}
func setup():
	if (lobby):
		var i = 0
		for client_id in lobby.clients.keys():
			client_id = int(1 if i == 0 else client_id)
			if (id != client_id):
#				awaiting_clients[client_id] = 0
				print("From Server Init:")
				_create_peer(client_id)
			i += 1
	rtc_mp.initialize(id, true)
	get_tree().set_network_peer(rtc_mp)
#	print("Awaitng Responses: ", awaiting_clients)
#	_check_setup()

func close():
	active = false
	ws_client.disconnect_from_host()

func peer_connected(this_id):
	return connected_peers.has(this_id)

func await_peer_connection(this_id):
	this_id = int(this_id)
	if (not awaiting_peers.has(this_id)):
		var state = _await_peer_connection(this_id)
		awaiting_peers[this_id] = state
		return state
	else:
		return awaiting_peers[this_id]

#### BACKGROUND FUNCTIONS ####

func _init():
	ws_client.connect("connection_established", self, "_connected")
	ws_client.connect("data_received", self, "_parse_msg")
	ws_client.connect("connection_closed", self, "_closed")
	ws_client.connect("connection_error", self, "_closed")
	ws_client.connect("server_close_request", self, "_close_request")
	
	rtc_mp.connect("connection_succeeded", self, "_rtc_connected")
	rtc_mp.connect("server_disconnected", self, "_rtc_disconnected")
	rtc_mp.connect("peer_connected", self, "_rtc_peer_connected")
	rtc_mp.connect("peer_disconnected", self, "_rtc_peer_disconnected")

func _rtc_connected():
	rtc_connected = true
	emit_signal("setup_completed")

func _rtc_disconnected():
	rtc_connected = false

func _rtc_peer_connected( this_id ): 
	print("UFCKING FUCK FUCK FUUUUCK (%s)" % this_id)
#	if (not awaiting_clients.has(this_id)):
#		emit_signal("peer_join", this_id)
#	else:
#		_check_setup(this_id)
	_send("peer_connected", this_id, null)
	if (not Network.peer_connected(this_id)): yield(Network.await_peer_connection(this_id), "completed")
	emit_signal("peer_connected", this_id)

func _rtc_peer_disconnected( this_id ): 
	print("boooowomp (%s)" % this_id)
	emit_signal("peer_leave", this_id)

func _emit(type, func_id, res):
	_send(type, res, func_id)
	yield()
	var to_return = awaiting_funcs[func_id]
	awaiting_funcs.erase(func_id)
	return to_return

func _send(type, res, func_id):
	var message = {
		"type": type,
		"res": res,
		"ID": func_id,
	}
	
	_basesend(JSON.print(message))

var send_mode = "WS"
func _basesend(string):
	if (connected):
		return ws_client.get_peer(1).put_packet((string).to_utf8())
	else:
		return 24

func _connected(protocol = ""):
	ws_client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	print("Socket Connected!")
	connected = true
	emit_signal("connected")

func _create_peer(this_id):
	print("Creating Peer (%s)" % this_id)
	var peer: WebRTCPeerConnection = WebRTCPeerConnection.new()
	peer.initialize({
		"iceServers": [ { "urls": ["stun:stun.l.google.com:19302"] } ]
	})
	peer.connect("session_description_created", self, "_offer_created", [this_id])
	peer.connect("ice_candidate_created", self, "_new_ice_candidate", [this_id])
	rtc_mp.add_peer(peer, this_id)
#	peer.create_offer()
	print("Comparing IDs: (%s - %s)" % [int(this_id), int(id)])
	if int(this_id) > int(id):
		peer.create_offer()
	return peer

func _await_peer_connection(this_id):
	yield()
	var to_return = awaiting_peers[this_id]
	awaiting_peers.erase(this_id)
	return to_return

func _offer_created(type, data, this_id):
	if not rtc_mp.has_peer(this_id):
		return
	print("created", type)
	rtc_mp.get_peer(this_id).connection.set_local_description(type, data)
	if type == "offer": Network.emit("offer", [this_id, data])
	else: Network.emit("answer", [this_id, data])

func _new_ice_candidate(mid_name, index_name, sdp_name, this_id):
	# this_id, mid_name, index_name, sdp_name
	 Network.emit("candidate", {
		"id": this_id,
		"mid": mid_name,
		"index": index_name,
		"sdp": sdp_name
	})

func _parse_msg():
	var data: String = ws_client.get_peer(1).get_packet().get_string_from_utf8()
	var data_res = JSON.parse(data)
	var message = data_res.result
	
	var type = message.type
	var func_id = null 
	if (message.ID != null):
		func_id = int(message.ID)
	var res = message.res
	
	if (awaiting_funcs.has(func_id)):
		var state = awaiting_funcs[func_id]
		awaiting_funcs[func_id] = res
		state.resume()
	else:
		match type:
			"init":
				true_id = int(res)
				id = true_id
			"joined_lobby":
				print("From WebSocket:")
#				awaiting_clients[res] = 0
				res.id = int(res.id)
				_create_peer(res.id)
				lobby.clients[str(res.id)] = {
					"username": res.username
				}
				emit_signal("peer_join", res.id, res.username)
			"peer_connected":
#				pass
				res = int(res)
				print("Hey uuuh, you're connected on Peer #%s end..." % res)
				connected_peers.append(res)
				if (awaiting_peers.has(res)):
					var state = awaiting_peers[res]
					awaiting_peers[res] = true
					state.resume()
#				_check_setup(res)
			"offer":
				var this_id = res[0]
				var offer = res[1]
				print("Got offer: %d" % this_id)
				if rtc_mp.has_peer(this_id):
					rtc_mp.get_peer(this_id).connection.set_remote_description("offer", offer)
			"answer":
				var this_id = res[0]
				var answer = res[1]
				print("Got answer: %d" % this_id)
				if rtc_mp.has_peer(this_id):
					rtc_mp.get_peer(this_id).connection.set_remote_description("answer", answer)
#				_check_setup(this_id)
			"candidate":
				var this_id = res.id
				var mid = res.mid
				var index = res.index
				var sdp = res.sdp
				
				print("Got candidate: %d" % this_id)
				if rtc_mp.has_peer(this_id):
					rtc_mp.get_peer(this_id).connection.add_ice_candidate(mid, index, sdp)

#func _check_setup( this_id = null ):
#	if (this_id != null and awaiting_clients.has(this_id)):
#		awaiting_clients[this_id] += 1
#
#		if (awaiting_clients[this_id] == 2):
#			emit_signal("peer_join", int(this_id))

func _closed(was_clean = false):
	print("Socket Closed: %s" % was_clean)
	emit_signal("disconnected")
	connected = false

func _close_request(code, reason):
	print("Socket Close Request: ( %s, %s )" % [code, reason])
#	self.code = code
#	self.reason = reason

func _process(_delta):
	var status:int = ws_client.get_connection_status()
	if status == WebSocketClient.CONNECTION_CONNECTING or status == WebSocketClient.CONNECTION_CONNECTED:
		ws_client.poll()
