class_name Player2D extends SyncCharacter2D

@export var speed : float = 100.0
@export var accel : float = 50

var jumps_left = 2


func _ready() -> void:
	input_node.set_multiplayer_authority(peer_id)
	super()


func movement_tick(tick: int, delta: float) -> void:
	$Label.text = str(global_position)
	var input_direction: float = input_node.get_axis("ui_left", "ui_right")
	
	#if rollback.correcting:
		#prints("rollback is correcting", tick, delta, input_direction, input_node.current_inputs)
	
	velocity.x = input_direction * speed
	if not is_on_floor():
		velocity.y = clamp(velocity.y + (get_gravity().y * delta), -1000, 1000)
	else:
		if velocity.y > 0: velocity.y = 0
		jumps_left = 2
	
	if input_node.is_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = -500
		if not is_on_floor() and jumps_left > 0:
			velocity.y = -500
			jumps_left -= 1
	
	move_and_slide()
