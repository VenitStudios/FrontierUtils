extends Node

signal new_loop (p_tick: int)
signal physics_tick (p_tick: int, p_physics_delta: float)
signal sync_tick (p_tick: int)

signal peer_connected (peer: int)
signal peer_disconnected (peer: int)


func _ready() -> void:
	connect_signals()


func connect_signals() -> void:
	multiplayer.peer_connected.connect(peer_connected.emit)
	multiplayer.peer_disconnected.connect(peer_disconnected.emit)


@rpc("authority", "call_local", "unreliable_ordered")
func _physics_tick(tick: int, delta: float) -> void: physics_tick.emit(tick, delta) 
@rpc("authority", "call_local", "unreliable_ordered")
func _sync_tick(tick: int) -> void: sync_tick.emit(tick) 
