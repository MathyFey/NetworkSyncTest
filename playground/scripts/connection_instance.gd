extends Node

# Usage:
# Create session sets the player login information to the active session
var active_session: Dictionary = {}

func create_session(session: Dictionary):
	active_session = session
	print("Session started, welcome ", active_session["username"])
	# print("[DEBUG] Session: ", active_session)


func get_active_session() -> Dictionary:
	return active_session


func get_active_user_id() -> int:
	if !active_session:
		return -1
	return active_session["id"]


func set_active_character_for_session(active_character_info: Dictionary):
	active_session["character"] = active_character_info

