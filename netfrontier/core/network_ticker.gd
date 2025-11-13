extends Node

var sync_interval: int = 2

func _physics_process(delta: float) -> void:
	if NetworkState.running:
		var tick: int = NetworkState.tick
		NetworkSignals.new_loop.emit(tick)
		NetworkSignals.physics_tick.emit(tick, delta)
		
		if tick % sync_interval == 0:
			NetworkSignals.sync_tick.emit(tick)
		
		NetworkState.tick += 1
		if multiplayer.is_server() and tick % 4 == 0:
			NetworkState.sync_time_from_server.rpc(tick, delta)
