extends Node

signal network_ready
signal network_start
signal network_end

var multiplayer_peer: MultiplayerPeer
var running: bool
var tick: int = 0
var client_ticks: Dictionary[int, int]

var tick_diff: int = 0

var server_delta: float
var ping_info: Dictionary

func _ready() -> void:
	network_ready.emit()
	
	multiplayer.connected_to_server.connect(func(): running = true)

func start_network_host_with_peer(p_peer: MultiplayerPeer) -> void:
	if running:
		print_debug("Network is already running!")
	else:
		print("Starting Network loop with peer %s" % p_peer)
		multiplayer_peer = p_peer
		running = true


func end_network() -> void:
	if running:
		if is_instance_valid(multiplayer_peer):
			multiplayer_peer.close()
			multiplayer_peer = null
		running = false


@rpc("authority", "call_remote")
func sync_time_from_server(p_tick: int = tick, delta: float = 1.0/60) -> void:
	tick = p_tick
	server_delta = delta

@rpc("any_peer", "call_remote")
func sync_time_from_client(p_tick: int = tick) -> void:
	if multiplayer.is_server():
		client_ticks[multiplayer.get_remote_sender_id()] = p_tick
		#prints("%s is %sms behind" % [multiplayer.get_remote_sender_id(), (tick-p_tick)*(1.0/60.0)*1000.0 ])

func compress_json(dictionary: Dictionary) -> Array:
	var buffer := var_to_bytes(dictionary)
	return [buffer.compress(FileAccess.COMPRESSION_ZSTD), buffer.size()]

func decompress_and_decode(compressed: PackedByteArray, size: int) -> Dictionary:
	var decompressed: PackedByteArray = compressed.decompress(size, FileAccess.COMPRESSION_ZSTD)
	var json = bytes_to_var(decompressed)
	return json

func send_peers_ping() -> void:
	if multiplayer.is_server():
		var peers := multiplayer.get_peers()
		for peer in peers:
			ping.rpc_id(peer)
			
			if not ping_info.has(peer): ping_info[peer] = {}
			ping_info[peer]["last_sent"] = Time.get_unix_time_from_system()


@rpc("authority", "call_local")
func ping() -> void:
	pong.rpc_id(1)

@rpc("any_peer", "call_local")
func pong() -> void:
	var peer: int = multiplayer.get_remote_sender_id()
	ping_info[peer]["last_recieved"] = Time.get_unix_time_from_system()
	#prints("ping for", peer, calculate_ping_ms(peer))

func calculate_ping(peer_id: int) -> float:
	return float(ping_info.get(peer_id, {}).get("last_recieved", 0))-float(ping_info.get(peer_id, {}).get("last_sent", 0))
func calculate_ping_ms(peer_id: int) -> int: return int(calculate_ping(peer_id) * 1000.0)
