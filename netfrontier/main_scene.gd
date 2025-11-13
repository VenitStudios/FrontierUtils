extends Node

const PLAYER_3D = preload("uid://bepm28jqhy8mo")
const PLAYER_2D = preload("uid://b14wiwrdbf1js")


func _ready() -> void:
	NetworkSignals.peer_connected.connect(add_player)
	NetworkSignals.physics_tick.connect(_on_physics_tick)

func _on_physics_tick(p_tick: int, p_physics_delta: float) -> void:
	%nettime.text = str(p_tick, "\n", 
	Engine.get_frames_per_second(), " fps",
	str(p_physics_delta * 1000.0).substr(0, 4),"\n", 
	abs(NetworkState.tick_diff), " - ", 
	snappedf(abs(NetworkState.tick_diff) * 1000.0/Engine.physics_ticks_per_second, .1), "ms",
	)


func host_pressed() -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(9090)
	multiplayer.multiplayer_peer = peer
	NetworkState.start_network_host_with_peer(peer)
	
	get_window().title += " (Server - %s %s)" % [multiplayer.get_unique_id(), OS.get_cmdline_args()[3]]
	
	add_player(1)
	$VBoxContainer.hide()
	
func client_pressed() -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_client("login-ver.gl.at.ply.gg", 33154)
	#peer.create_client("localhost", 9090)
	multiplayer.multiplayer_peer = peer
	get_window().title += " (Client - %s %s)" % [multiplayer.get_unique_id(), OS.get_cmdline_args()[3]]
	
	multiplayer.connected_to_server.connect(add_player.bind(multiplayer.get_unique_id()))
	$VBoxContainer.hide()

func add_player(peer) -> void:
	var player := PLAYER_3D.instantiate()
	player.peer_id = peer
	player.set_name(str(peer))
	%Players.add_child(player)
