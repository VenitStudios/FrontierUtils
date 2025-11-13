class_name Player3D extends SyncCharacter3D

@export var speed : float = 10.0
@export var accel : float = 5

var jumps_left = 2


func _ready() -> void:
	input_node.set_multiplayer_authority(peer_id)
	super()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func movement_tick(tick: int, delta: float) -> void:
	
	global_rotation.y = input_node.read_vector2("head_rotation").y
	$Camera3D.rotation.x = input_node.read_vector2("head_rotation").x
	
	var input_direction: Vector2 = input_node.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction: Vector3 = global_basis * Vector3(input_direction.x, 0, input_direction.y)
	
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	if not is_on_floor():
		velocity.y = clamp(velocity.y + (get_gravity().y * delta), -1000, 1000)
	else:
		if velocity.y > 0: velocity.y = 0
		jumps_left = 2
	
	if input_node.is_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = 5
		if not is_on_floor() and jumps_left > 0:
			velocity.y = 5
			jumps_left -= 1
	if rollback.correcting:
		move_and_slide()

func _physics_process(delta: float) -> void:
	if not rollback.correcting: move_and_slide()
