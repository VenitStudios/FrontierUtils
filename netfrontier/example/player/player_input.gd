class_name PlayerInput extends InputSynchronizer

var head_rotation: Vector2 

func _ready() -> void:
	super()
	
	start_reading_strengths(["ui_left", "ui_right", "ui_up", "ui_down"])
	start_reading_press("ui_accept")
	start_reading_vector("head_rotation")

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion:
		var relative: Vector2 = event.relative * get_process_delta_time()
		head_rotation.x = clamp(head_rotation.x-relative.y, -PI/2, PI/2)
		head_rotation.y -= relative.x
