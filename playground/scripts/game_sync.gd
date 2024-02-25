extends GdSceneSynchronizer

const IP_ADDRESS: String = "127.0.0.1"
const PORT: int = 9999

var player_information: Dictionary = {}

@onready var player_scene := preload("res://playground/character.tscn")

func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)


func start_server():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, 99)

	if error != OK:
		print("Cannot host - Error: ", error)
		return

	multiplayer.multiplayer_peer = peer
	print("[", multiplayer.get_unique_id(), "] Waiting for players")

	var character_info: Dictionary = {}
	character_info["nickname"] = ConnectionInstance.get_active_session()["character"]["nickname"]
	character_info["first_name"] = ConnectionInstance.get_active_session()["character"]["first_name"]
	character_info["last_name"] = ConnectionInstance.get_active_session()["character"]["last_name"]

	add_player_info(1, character_info)

	clear()
	reset_synchronizer_mode()


func start_client():
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)

	multiplayer.multiplayer_peer = peer
	print("[", multiplayer.get_unique_id(), "] Attempting to connect to ", IP_ADDRESS, ":", PORT)

	clear()
	reset_synchronizer_mode()


func peer_connected(id: int):
	print("[", multiplayer.get_unique_id(), "]", " ++ New player connected: ", id)
	# spawn_character_for_newly_connected_player.rpc(id)


func peer_disconnected(id: int):
	print("[", multiplayer.get_unique_id(), "]", " -- Player disconnected: ", id)


func connected_to_server():
	print("[", multiplayer.get_unique_id(), "]", " Connection established!")

	print("[", multiplayer.get_unique_id(), "]", " Sending player character_info to host!")

	var character_info: Dictionary = {}
	character_info["nickname"] = ConnectionInstance.get_active_session()["character"]["nickname"]
	character_info["first_name"] = ConnectionInstance.get_active_session()["character"]["first_name"]
	character_info["last_name"] = ConnectionInstance.get_active_session()["character"]["last_name"]

	add_player_info.rpc_id(1, multiplayer.get_unique_id(), character_info)


func connection_failed():
	print("[", multiplayer.get_unique_id(), "]", "[ERROR] ID= ", multiplayer.get_unique_id(), " connection failed!")


@rpc("any_peer", "call_local")
func start_match():
	print("[", multiplayer.get_unique_id(), "] Starting match")

	var spawn_point_index: int = 0
	var spawn_points: Array = []
	spawn_points = get_tree().get_nodes_in_group("spawn_point")
	for player in player_information:
		spawn_character(player, spawn_points[spawn_point_index])
		spawn_point_index += 1


@rpc("any_peer")
func add_player_info(player_peerid: int, player_info: Dictionary):
	if not player_information.has(player_peerid):
		player_information[player_peerid] = player_info

	if multiplayer.is_server():
		for key in player_information:
			add_player_info.rpc(key, player_info)  # Corrected this line


func spawn_character(id: int, spawn_point: Node3D):
	var player = player_scene.instantiate()
	player.name = str(id)
	player.register_player()
	get_tree().root.get_node("Dev").add_child(player)
	player.global_position = spawn_point.global_position
