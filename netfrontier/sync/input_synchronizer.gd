class_name InputSynchronizer extends Node

var current_inputs: Dictionary[String, Variant]
var reading_press: PackedStringArray
var reading_strength: PackedStringArray

var last_strength: Dictionary[String, float]

var just_pressed: Array
var just_released: Array

var reading_vector: PackedStringArray
var current_vec2: Dictionary[String, Variant]
var current_vec3: Dictionary[String, Variant]

var current_tick: int # used for correction

## used so stuff like the mouse scroll wheel can be detected easily
var local_press_states : Dictionary[String, bool]
 
func _ready() -> void:
	NetworkSignals.new_loop.connect(_on_new_loop)


func _on_new_loop(p_tick: int) -> void:
	reset()


func _input(event: InputEvent) -> void:
	if is_multiplayer_authority() and get_window().has_focus():
		current_tick = NetworkState.tick
		for input in reading_press:
			var state := Input.is_action_pressed(input)
			if not state == local_press_states.get_or_add(input, false):
				local_press_states[input] = state
				if state:
					await NetworkSignals.sync_tick
					input_just_pressed.rpc(input)
				else:
					await NetworkSignals.new_loop
					input_just_released.rpc(input)
			
		for strength in reading_strength:
			if Input.get_action_raw_strength(strength) != last_strength.get_or_add(strength, 0.0):
				input_strength.rpc(strength, Input.get_action_raw_strength(strength))
				input_strength(strength, Input.get_action_raw_strength(strength))
				last_strength[strength] = Input.get_action_raw_strength(strength)
		
		for vector in reading_vector:
			match typeof(get(vector)):
				TYPE_VECTOR2, TYPE_VECTOR2I:
					current_vec2[vector] = get(vector)
				TYPE_VECTOR3, TYPE_VECTOR3I:
					current_vec3[vector] = get(vector)


func reset() -> void:
	if not multiplayer.is_server() and is_multiplayer_authority():
		send_buffers_to_server.rpc(just_pressed, just_released, current_vec2, current_vec3, current_tick)
		#print(current_vec2, W)
	just_pressed.clear()
	just_released.clear()


@rpc("any_peer", "call_local", "reliable")
func input_just_pressed(input_name: String) -> void:
	await NetworkSignals.new_loop
	if just_released.has(input_name): just_released.erase(input_name)
	if not just_pressed.has(input_name): just_pressed.append(input_name)
	current_inputs[input_name] = true


@rpc("any_peer", "call_local", "reliable")
func input_just_released(input_name: String) -> void:
	await NetworkSignals.new_loop
	if just_pressed.has(input_name): just_pressed.erase(input_name)
	if not just_released.has(input_name): just_released.append(input_name)
	current_inputs[input_name] = false


@rpc("any_peer", "call_local", "reliable")
func input_strength(input_name: String, strength: float) -> void:
	await NetworkSignals.new_loop
	current_inputs[input_name] = strength


@rpc("any_peer", "call_remote", "unreliable_ordered")
func send_buffers_to_server(s_just_pressed: PackedStringArray=[], s_just_released:PackedStringArray=[], vec2:Dictionary={}, vec3:Dictionary={}, p_tick:int=NetworkState.tick) -> void:
	if multiplayer.is_server():
		#prints(get_multiplayer_authority(), multiplayer.get_remote_sender_id(), current_vec2, current_vec3)
		
		just_pressed = s_just_pressed
		just_released = s_just_released
		current_tick = p_tick
		
		current_vec2 = vec2
		current_vec3 = vec3

func start_reading_vector(input_name: String) -> void:
	if not reading_vector.has(input_name): reading_vector.append(input_name)

func start_reading_press(input_name: String) -> void:
	if not reading_press.has(input_name): reading_press.append(input_name)
	#print(reading_press)


func start_reading_strengths(input_names: PackedStringArray) -> void:
	for input_name in input_names: start_reading_strength(input_name)


func start_reading_strength(input_name: String) -> void:
	if not reading_strength.has(input_name): reading_strength.append(input_name)


func is_pressed(input_name: String) -> bool:
	return bool(current_inputs.get(input_name, false))

func is_just_pressed(input_name: String) -> bool:
	return just_pressed.has(input_name)


func is_just_released(input_name: String) -> bool:
	return just_released.has(input_name)


func get_strength(input_name: String) -> float:
	return float(current_inputs.get(input_name, 0.0))


func read_vector2(input_name: String) -> Vector2: return Vector2(current_vec2.get(input_name, Vector2.ZERO))
func read_vector3(input_name: String) -> Vector3: return Vector3(current_vec3.get(input_name, Vector3.ZERO))


#this function is a GDScript port of Input.get_axis() https://github.com/godotengine/godot/blob/6fd949a6dcbda94140200633394f2b4b99de8f6f/core/input/input.cpp#L542
func get_axis(p_negative_action: StringName, p_positive_action: StringName) -> float:
	return get_strength(p_positive_action) - get_strength(p_negative_action)


#this function is a GDScript port of Input.get_vector() https://github.com/godotengine/godot/blob/6fd949a6dcbda94140200633394f2b4b99de8f6f/core/input/input.cpp#L546
func get_vector(p_negative_x: StringName, p_positive_x: StringName, p_negative_y: StringName, p_positive_y: StringName, deadzone: float = -1.0) -> Vector2:
	var vector : Vector2 = Vector2(
		get_strength(p_positive_x) - get_strength(p_negative_x),
		get_strength(p_positive_y) - get_strength(p_negative_y),
	)
	
	if deadzone < 0.0:
		deadzone = .25 * (
		InputMap.action_get_deadzone(p_positive_x) +
		InputMap.action_get_deadzone(p_negative_x) +
		InputMap.action_get_deadzone(p_positive_y) +
		InputMap.action_get_deadzone(p_negative_y)
		)
	
	var length : float = vector.length()
	if length <= deadzone:
		return Vector2()
	elif length > 1:
		return vector / length
	else:
		return vector * (inverse_lerp(deadzone, 1.0, length) / length)
