extends CharacterBody3D

func _ready() -> void:
	
	# Register the node as synchronized. This will create a NetId and call `_setup_synchronizer`.
	# set_multiplayer_authority(multiplayer.get_unique_id())
	GameSync.register_node(self)

func _setup_synchronizer(local_id) -> void:
	
	# This function is called by the NetworkSynchronizer to setup the node synchronization model.
	# The function `setup_controller` is used to specify the functions that will control the character.
	GameSync.setup_controller(self, get_multiplayer_authority(), _collect_inputs, _count_input_size, _are_inputs_different, _controller_process)
	
	# Register all the variables to keep in sync that the function `_controller_process` modifies.
	GameSync.register_variable(self, "velocity")
	GameSync.register_variable(self, "transform")

# Networking
func _collect_inputs(delta: float, buffer: DataBuffer) -> void:
	
	# This function is called by the NetworkSynchronizer each frame, only on the client side, to collect the player&#39;s input into the buffer.
	var input_direction := Vector2()
	var wants_to_jump: bool = false

	input_direction = Input.get_vector("left", "right", "forward", "backward")

	if Input.is_action_pressed("jump"):
		wants_to_jump = true

	buffer.add_vector2(input_direction)
	buffer.add_bool(wants_to_jump)

func _count_input_size(inputs: DataBuffer) -> int:
	
	# This function is called by the NetworkSynchronizer to read the buffer size.
	# To keep the buffer as small as possible, to save bandwidth, the buffer size isa never stored.
	var size = 0
	size += inputs.get_vector2_size()
	size += inputs.get_bool_size()

	return size

func _are_inputs_different(inputs_A: DataBuffer, inputs_B: DataBuffer) -> bool:
	
	# The NetworkSynchronizer will call this function to compare two input buffers.
	if inputs_A.size != inputs_B.size:
		return true

	var input_direction_A = inputs_A.read_vector2()
	var input_direction_B = inputs_B.read_vector2()

	if input_direction_A != input_direction_B:
		return true

	var jump_A: bool = inputs_A.read_bool()
	var jump_B: bool = inputs_B.read_bool()

	if jump_A != jump_B:
		return true

	return false

func _controller_process(delta: float, buffer: DataBuffer) -> void:
	
	# This function is executed by the NetworkSynchronizer each frame, on the clients and the server, to advance the simulation.
	# The buffer contains the player&#39;s input that you can read as follows.
	var input_direction: Vector2 = buffer.read_vector2()
	var wants_to_jump: bool = buffer.read_bool()

	move_the_character(delta, input_direction, wants_to_jump)

func move_the_character(delta, input_direction, wants_to_jump):

	var horizontal_velocity: Vector3 = Vector3(input_direction.x, velocity.y, input_direction.y) * delta
	velocity = horizontal_velocity
	
	if wants_to_jump:
		velocity.y += 200.0

	move_and_slide()
