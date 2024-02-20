extends GdSceneSynchronizer

const IP_ADDRESS: String = "127.0.0.1"
const PORT: int = 9999

@onready var player_scene := preload("res://character.tscn")

func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)

func start_server():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, 99)
	multiplayer.multiplayer_peer = peer

	clear()
	reset_synchronizer_mode()

func start_client():
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer

	clear()
	reset_synchronizer_mode()

func peer_connected(id: int):
	print("[", multiplayer.get_unique_id(), "]", " ++ New player connected: ", id)
	spawn_player.rpc_id(id, id)

func peer_disconnected(id: int):
	print("[", multiplayer.get_unique_id(), "]", " -- Player disconnected: ", id)

func connected_to_server():
	print("[", multiplayer.get_unique_id(), "]", " Connection established!")

func connection_failed():
	print("[", multiplayer.get_unique_id(), "]", "[ERROR] ID= ", multiplayer.get_unique_id(), " connection failed!")

@rpc("any_peer", "reliable")
func spawn_player(id: int):
	var player = player_scene.instantiate()
	player.set_multiplayer_authority(id)
	player.name = str(id)
	print(multiplayer.get_remote_sender_id())
	get_tree().root.get_node("Dev").add_child(player)

