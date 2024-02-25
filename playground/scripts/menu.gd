extends CanvasLayer

@onready var menu := $PanelContainer/GridContainer
@onready var start_button = $PanelContainer/StartButton

func _on_server_pressed():
	GameSync.start_server()
	menu.visible = false
	start_button.visible = true


func _on_client_pressed():
	GameSync.start_client()
	visible = false



func _on_start_button_pressed():
	GameSync.start_match.rpc()
	visible = false
