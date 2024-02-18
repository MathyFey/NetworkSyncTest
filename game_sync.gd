extends GdSceneSynchronizer

const IP_ADDRESS: String = "127.0.0.1"
const PORT: int = 9999

@onready var player_scene := preload ("res://character.tscn")

func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)

func start_server():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, 99)
	multiplayer.multiplayer_peer = peer

func start_client():
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer

func peer_connected(id: int):
	print("++ New player connected: ", id)
	# spawn_player(id)

func peer_disconnected(id: int):
	print("-- Player disconnected: ", id)

func connected_to_server():
	print("ID= ", multiplayer.get_unique_id(), " connection established!")

func connection_failed():
	print("[ERROR] ID= ", multiplayer.get_unique_id(), " connection failed!")

func spawn_player(id: int):
	var player = player_scene.instantiate()
	player.set_multiplayer_authority(id)
	player.name = str(id)
	player.global_position = Vector3(randf_range( - 7, 7), 0, randf_range( - 7, 7))
	get_tree().root.add_child(player)
