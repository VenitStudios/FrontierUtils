class_name Rollback extends Node

var root: Node
var input_node: PlayerInput
var peer: int

var correcting: bool

var tracked_properties: Dictionary
var property_buffer: Dictionary[int, Variant]
var input_buffer: Dictionary[int, Dictionary]

var max_buffer_size: int = 1000
var distance_limit: float = 1.0

func _init(p_distance_limit: float) -> void:
	set_name("RollbackHandler")
	distance_limit = p_distance_limit

func _ready() -> void:
	NetworkSignals.new_loop.connect(_on_new_loop)

func _on_new_loop(p_tick: int) -> void:
	if is_instance_valid(root) and is_instance_valid(input_node):
		if multiplayer.is_server() and not peer == multiplayer.get_unique_id():
			compare_with_client(input_node.current_tick)
		else:
			feed_buffer(p_tick)


# this is an ominous function name - cs
func feed_buffer(p_tick: int) -> void:
	if not property_buffer.has(p_tick): property_buffer[p_tick] = {}
	if not input_buffer.has(p_tick): input_buffer[p_tick] = {}
	
	input_buffer[p_tick]["pressed"] = input_node.just_pressed
	input_buffer[p_tick]["released"] = input_node.just_released
	input_buffer[p_tick]["total"] = input_node.current_inputs
	input_buffer[p_tick]["vec2"] = input_node.current_vec2
	input_buffer[p_tick]["vec3"] = input_node.current_vec3
	
	for index: int in tracked_properties.size():
		property_buffer[p_tick][index] = root.get(tracked_properties.keys()[index])
	
	for i in property_buffer.size()-max_buffer_size: property_buffer.erase(property_buffer.keys()[0])
	for i in input_buffer.size()-max_buffer_size: input_buffer.erase(input_buffer.keys()[0])


func compare_with_client(p_tick: int) -> void:
	var comparison_data: Dictionary
	for index: int in tracked_properties.size(): 
		comparison_data[index] = root.get(tracked_properties.keys()[index])
	compare_buffer.rpc_id(peer, p_tick, comparison_data)


@rpc("authority", "call_remote")
func compare_buffer(p_tick: int, p_data: Dictionary) -> void:
	if not multiplayer.is_server() and input_node.is_multiplayer_authority():
		NetworkState.tick_diff = p_tick - NetworkState.tick
		var should_correct: bool = false
		if property_buffer.has(p_tick):
			var client_data: Variant = property_buffer.get(p_tick)
			
			for idx in p_data.keys():
				var property_key: String = tracked_properties.keys()[idx]
				var server_property_value: Variant = p_data.get(idx)
				var client_property_value: Variant = client_data.get(idx)
				
				var distance: float
				
				match typeof(server_property_value):
					TYPE_VECTOR2, TYPE_VECTOR2I, TYPE_VECTOR3, TYPE_VECTOR3I:
						distance = server_property_value.distance_to(client_property_value)
					TYPE_FLOAT, TYPE_INT:
						distance = abs(server_property_value - client_property_value)
				
				if distance > distance_limit and tracked_properties.get(property_key, false): 
					
					should_correct = true
			
			if should_correct:
				rollback_and_replay(p_tick, p_data)

func rollback_and_replay(p_tick: int, p_data: Dictionary) -> void:
	correcting = true
	var ticks_to_replay: int = int(property_buffer.keys().back()) - p_tick # get highest tick in buffer
	var client_data: Variant = property_buffer.get(p_tick)
	
	for idx in p_data.keys():
		var property_key: String = tracked_properties.keys()[idx]
		
		var server_property_value: Variant = p_data.get(idx)
		var client_property_value: Variant = client_data.get(idx)
		
		if tracked_properties.get(property_key, false): 
			#root.set(property_key, server_property_value)
			var tween : Tween = create_tween()
			tween.tween_property(root, property_key, server_property_value, 0.05)
			#await tween.finished
		
		if p_tick % 2 == 0 and property_key == "global_position" and root is SyncCharacter3D:
			pass
			#add_mesh(server_property_value, Color.RED, distance_limit+0.02)
			#add_mesh(client_property_value, Color.BLUE, distance_limit-0.02)

	for i: int in ticks_to_replay:
		var bidx: int = p_tick + i
		
		if input_buffer.has(bidx):
			# this is scuffed lmao - cs
			input_node.just_pressed = input_buffer[bidx]["pressed"]
			input_node.just_released = input_buffer[bidx]["released"]
			input_node.current_inputs = input_buffer[bidx]["total"]
		
		if root.has_method("movement_tick"):
			root.call("movement_tick", p_tick, NetworkState.server_delta)
		
		for index: int in tracked_properties.size():
			if property_buffer.has(bidx):
				property_buffer[bidx][index] = root.get(tracked_properties.keys()[index])
		
	correcting = false


func add_tracked_property(property: StringName, use_for_correction: bool) -> void: 
	if not tracked_properties.has(property): tracked_properties[property] = use_for_correction

func remove_tracked_property(property: StringName) -> void: 
	if tracked_properties.has(property): tracked_properties.erase(property)

var debug_labels: Array[Label]

var meshes: Array[MeshInstance3D]

func add_mesh(position: Vector3, color: Color, radius: float) -> void:
	var meshinst := MeshInstance3D.new()
	
	meshinst.mesh = SphereMesh.new()
	meshinst.mesh.radius = radius/2
	meshinst.mesh.height = radius
	
	meshinst.mesh.radial_segments = 16
	meshinst.mesh.rings = 8
	
	meshinst.material_override = ShaderMaterial.new()
	
	var shader := Shader.new()
	#shader.code = "sShader_type spatial; uniform vec3 color; void fragment() {ALBEDO = color;}"
	shader.code = "shader_type spatial; render_mode wireframe; uniform vec3 color; void fragment() {ALBEDO = color;}"
	
	meshinst.material_override.shader = shader
	meshinst.material_override.set_shader_parameter("color", color)
	get_tree().root.add_child(meshinst)
	meshinst.global_position = position
	
	meshes.append(meshinst)
	for i in meshes.size()-50:
		meshes[0].queue_free()
		meshes.erase(meshes[0])

func add_client_server_debug_2d(tick: int, server_pos: Vector2, client_pos: Vector2):
	var cr := Label.new()
	get_tree().root.add_child(cr)
	cr.modulate = Color.RED
	cr.modulate.a = .2
	#cr.text = str(snappedf(server_pos.distance_to(client_pos),.1))
	cr.text = str(tick)
	cr.global_position = server_pos
	debug_labels.append(cr)
	
	cr = Label.new()
	get_tree().root.add_child(cr)
	cr.modulate = Color.BLUE
	cr.modulate.a = .2
	#cr.text = str(snappedf(server_pos.distance_to(client_pos),.1))
	cr.text = str(tick)
	cr.global_position = client_pos
	debug_labels.append(cr)
	
	for i in debug_labels.size()-50:
		debug_labels[0].queue_free()
		debug_labels.erase(debug_labels[0])
