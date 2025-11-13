extends Node

signal network_ready
signal network_start
signal network_end


var multiplayer_peer: MultiplayerPeer
var running: bool
var tick: int = 0

var tick_diff: int = 0

var server_delta: float

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
