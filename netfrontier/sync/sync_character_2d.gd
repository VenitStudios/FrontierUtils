class_name SyncCharacter2D extends CharacterBody2D

@export var input_node : PlayerInput

var peer_id: int
var rollback := Rollback.new(1)

var last_delta: float

func _ready() -> void:
	add_rollback(input_node)
	NetworkSignals.sync_tick.connect(send_character_sync)
	NetworkSignals.physics_tick.connect(_on_physics_tick)


func add_rollback(p_input: PlayerInput) -> void:
	rollback.root = self
	add_child(rollback)
	
	rollback.peer = peer_id
	rollback.input_node = p_input
	
	rollback.add_tracked_property("global_position", true)
	rollback.add_tracked_property("velocity", false)

func _on_physics_tick(p_tick: int, p_physics_delta: float) -> void: 
	if not rollback.correcting: 
		last_delta = p_physics_delta
		movement_tick(p_tick, p_physics_delta)

func movement_tick(tick: int, delta: float) -> void: pass


func send_character_sync(p_tick: int) -> void:
	if multiplayer.is_server() and NetworkState.running:
		recieve_character_sync.rpc(global_transform, velocity)


@rpc("authority", "call_remote")
func recieve_character_sync(p_transform: Transform2D, p_vel: Vector2) -> void:
	if not peer_id == multiplayer.get_unique_id():
		global_transform = p_transform
		velocity = p_vel
