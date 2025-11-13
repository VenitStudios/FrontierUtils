class_name SyncCharacter3D extends CharacterBody3D

@export var input_node : PlayerInput

var peer_id: int
var rollback : Rollback

var last_delta: float

func _ready() -> void:
	add_rollback(input_node)
	NetworkSignals.sync_tick.connect(send_character_sync)
	NetworkSignals.physics_tick.connect(_on_physics_tick)


func add_rollback(p_input: PlayerInput) -> void:
	rollback = Rollback.new(.2)
	rollback.root = self
	
	rollback.peer = peer_id
	rollback.input_node = p_input
	
	add_child(rollback)
	add_rollback_items()

func add_rollback_items() -> void: pass


func movement_tick(tick: int, delta: float) -> void: pass

func _on_physics_tick(p_tick: int, p_physics_delta: float) -> void: 
	if not rollback.correcting: 
		last_delta = p_physics_delta
		movement_tick(p_tick, p_physics_delta)
		#prints("physics tick", p_tick, p_physics_delta, multiplayer.get_unique_id())

func send_character_sync(p_tick: int) -> void:
	if multiplayer.is_server() and NetworkState.running:
		recieve_character_sync.rpc(global_transform, velocity)


@rpc("authority", "call_remote")
func recieve_character_sync(p_transform: Transform3D, p_vel: Vector3) -> void:
	if not peer_id == multiplayer.get_unique_id():
		global_transform = p_transform
		velocity = p_vel
