extends Label3D

func _process(_delta):
	text = str("Authority: ", get_multiplayer_authority(), " || Unique ID: ", multiplayer.get_unique_id())
