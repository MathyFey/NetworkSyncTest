extends CanvasLayer

@onready var menu := $PanelContainer

func _on_server_pressed():
	GameSync.start_server()
	menu.visible = false

func _on_client_pressed():
	GameSync.start_client()
	menu.visible = false

