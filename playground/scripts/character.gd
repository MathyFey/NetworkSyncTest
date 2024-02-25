extends CharacterBody3D

const GRAVITY: float = 114
const FRICTION: float = 0.16
const VELOCITY_ZERO_THRESHOLD: float = 0.1

var max_speed: float = 15.0
var jump_force: float = 40.0
var acceleration: float = 360.0

@onready var NameTag := $NameTag

func _ready() -> void:
	# Register the node as synchronized. This will create a NetId and call `_setup_synchronizer`.
	# GameSync.register_node(self)
	NameTag.text = str(ConnectionInstance.get_active_session()["character"]["first_name"], " ", ConnectionInstance.get_active_session()["character"]["last_name"])
	set_multiplayer_authority(str(name).to_int())


func register_player():
	GameSync.register_node(self)
	GameSync.register_node(NameTag)

	# NameTag.text = str(ConnectionInstance.get_active_session()["character"]["first_name"], " ", ConnectionInstance.get_active_session()["character"]["last_name"])


# This function is called by the NetworkSynchronizer to setup the node synchronization model.
func _setup_synchronizer(_local_id) -> void:
	# The function `setup_controller` is used to specify the functions that will control the character.
	GameSync.setup_controller(self, get_multiplayer_authority(), _collect_inputs, _count_input_size, _are_inputs_different, _controller_process)

	# Register all the variables to keep in sync that the function `_controller_process` modifies.
	GameSync.register_variable(self, "velocity")
	GameSync.register_variable(self, "position")
	GameSync.register_variable(self, "rotation")
	GameSync.register_variable(NameTag, "text")


# This function is called by the NetworkSynchronizer each frame, only on the client side, to collect the player`s input into the buffer.
func _collect_inputs(_delta: float, buffer: DataBuffer) -> void:
	var input_direction := Vector2()
	var wants_to_jump: bool = false

	input_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	if Input.is_action_pressed("jump"):
		wants_to_jump = true

	buffer.add_vector2(input_direction)
	buffer.add_bool(wants_to_jump)


# This function is called by the NetworkSynchronizer to read the buffer size.
func _count_input_size(inputs: DataBuffer) -> int:
	# To keep the buffer as small as possible, to save bandwidth, the buffer size isa never stored.
	var size = 0
	size += inputs.get_vector2_size()
	size += inputs.get_bool_size()

	return size


# The NetworkSynchronizer will call this function to compare two input buffers.
func _are_inputs_different(inputs_A: DataBuffer, inputs_B: DataBuffer) -> bool:
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


# This function is executed by the NetworkSynchronizer each frame, on the clients and the server, to advance the simulation.
func _controller_process(delta: float, buffer: DataBuffer) -> void:
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		return
	# The buffer contains the player`s input that you can read as follows.
	var input_direction: Vector2 = buffer.read_vector2()
	var wants_to_jump: bool = buffer.read_bool()


	move_the_character(delta, input_direction, wants_to_jump)


func move_the_character(delta, input_direction, wants_to_jump):
	var move_direction: Vector3 = Vector3(input_direction.x, 0.0, input_direction.y).normalized()
	var horizontal_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var vertical_velocity: float = velocity.y

	if not move_direction.is_zero_approx():
		horizontal_velocity += move_direction * acceleration * delta

	if wants_to_jump and is_on_floor():
		vertical_velocity += jump_force

	# Set to zero to prevent small float desyncs
	if horizontal_velocity.length() < VELOCITY_ZERO_THRESHOLD and move_direction.is_zero_approx():
		horizontal_velocity = Vector3.ZERO

	if not is_on_floor():
		vertical_velocity -= GRAVITY * delta
	# Prevent gravity from accumulating while on the ground
	elif not wants_to_jump:
		vertical_velocity = 0.0

	if is_on_floor() and move_direction.is_zero_approx():
		horizontal_velocity = horizontal_velocity.lerp(Vector3.ZERO, FRICTION)

	velocity = horizontal_velocity.limit_length(max_speed) + Vector3(0.0, vertical_velocity, 0.0)

	# Orient to velocity
	if horizontal_velocity.normalized().length_squared() >= VELOCITY_ZERO_THRESHOLD:
		look_at(position + horizontal_velocity.normalized(), Vector3.UP, true)

	move_and_slide()
