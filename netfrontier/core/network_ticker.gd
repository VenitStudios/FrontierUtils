extends Node

var sync_interval: int = 2

func _physics_process(delta: float) -> void:
	if NetworkState.running:
		sync_interval = 2
		var tick: int = NetworkState.tick
		NetworkSignals.new_loop.emit(tick)
		NetworkSignals.physics_tick.emit(tick, delta)
		
		if tick % sync_interval == 0:
			NetworkSignals.sync_tick.emit(tick)
		
		NetworkState.tick += 1
		if tick % 4 == 0:
			if multiplayer.is_server():
				NetworkState.sync_time_from_server.rpc(NetworkState.tick, delta)
			else:
				NetworkState.sync_time_from_client.rpc(NetworkState.tick)
		if tick % 20 == 0:
				NetworkState.send_peers_ping()
