extends CanvasLayer


const CHARACTER_BUTTON: PackedScene = preload("res://playground/character_slot_button.tscn")

# Main tab: Tabs
enum MainTab {
	CONNECTION,
	CHARACTERS,
	CHARACTER_CREATION
}

# Character select: Tabs
enum CharacterSelectTab {
	ALL_CHARACTERS,
	NO_CHARACTERS_FOUND
}

var database: SQLite

@onready var main_tab := $MainTab
@onready var character_select_create_tab := $MainTab/Characters/MarginContainer/TabContainer/SelectCharacter
@onready var login_register_tab := $MainTab/Connect/TabContainer
# Popups
@onready var error_popup := $MainTab/Connect/ErrorPopup
@onready var error_popup_label := $MainTab/Connect/ErrorPopup/Label
@onready var popup_box := $MainTab/Connect/Popup
@onready var popup_label := $MainTab/Connect/Popup/Label
# Login
@onready var login_username_field := $MainTab/Connect/TabContainer/Login/VBoxContainer/GridContainer/Username
@onready var login_password_field := $MainTab/Connect/TabContainer/Login/VBoxContainer/GridContainer/Password
# Register
@onready var register_username_field := $MainTab/Connect/TabContainer/Register/VBoxContainer/GridContainer/Username
@onready var register_password_field := $MainTab/Connect/TabContainer/Register/VBoxContainer/GridContainer/Password
@onready var register_reenter_password_field := $MainTab/Connect/TabContainer/Register/VBoxContainer/GridContainer/Password2
@onready var register_email_field := $MainTab/Connect/TabContainer/Register/VBoxContainer/GridContainer/Email
# Creation
@onready var creation_first_name := $MainTab/Create/MarginContainer/Control/CharInfo/MarginContainer/VBoxContainer/GridContainer/FirstName
@onready var creation_last_name := $MainTab/Create/MarginContainer/Control/CharInfo/MarginContainer/VBoxContainer/GridContainer/LastName
@onready var creation_nickname := $MainTab/Create/MarginContainer/Control/CharInfo/MarginContainer/VBoxContainer/GridContainer/Nickname
@onready var creation_character_container := $MainTab/Characters/MarginContainer/TabContainer/SelectCharacter/MarginContainer/CharacterContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	database = SQLite.new()
	database.path = "res://GEAR_ZERO/data/main.sqlite"
	database.open_db()


func _on_register_pressed():
	if register_username_field.text.is_empty() or register_password_field.text.is_empty() or register_reenter_password_field.text.is_empty() or register_email_field.text.is_empty():
		popup_error("[ERROR] Please fill all the fields before trying to create an account!")

	if register_password_field.text != register_reenter_password_field.text:
		popup_error("[ERROR] Passwords do not match!")

	register_account()


func register_account():
	var account: = {
		"username": register_username_field.text,
		"password": register_password_field.text,  #TODO: HASH THE PASSWORD INSTEAD
		"email": register_email_field.text
	}
	var result: = database.insert_row("user", account)

	print(account)

	if result == false:
		popup_error("[ERROR] Issue while updating database")
		return

	print("Account created successfully")
	var rows = database.select_rows("user", "", ["*"])
	for row in rows:
		print(row)

	login_register_tab.current_tab = 0  # Login


func _on_login_button_pressed():
	if login_username_field.text.is_empty() or login_password_field.text.is_empty():
		popup_error("[ERROR] Not all fields are filled!")
		return

	database.query_with_bindings("SELECT * FROM user
								WHERE username = ? AND password = ? ",
								[login_username_field.text, login_password_field.text])

	var result: = database.query_result

	if !result:
		popup_error("[ERROR] Either username or password are invalid!")
		return

	popup_message(str("Login successfull, welcome ", login_username_field.text))
	ConnectionInstance.create_session(result[0])

	main_tab.current_tab = MainTab.CHARACTERS


func popup_error(error_message: String):
	print(error_message)
	error_popup_label.text = error_message
	error_popup.popup()


func popup_message(message: String):
	print(message)
	popup_label.text = message
	popup_box.popup()


func _on_create_new_character_button_pressed():
	main_tab.current_tab = MainTab.CHARACTER_CREATION


func _on_confim_character_button_pressed():

	if ConnectionInstance.get_active_session().is_empty():
		popup_error("[ERROR] No active session!")
		return

	# database.insert_row("character", {"user_id": active_user["id"]})
	var query_success := database.query_with_bindings("
		INSERT INTO character(user_id, experience)
		VALUES( ? , 0);
		SELECT last_insert_rowid(); ",
		[ConnectionInstance.get_active_user_id()])

	if query_success == false:
		popup_error("[ERROR] Issue while creating character!")
		return


	var inserted_char_id: int = database.query_result[0]["last_insert_rowid()"]
	print(inserted_char_id)

	#TODO: Link checkboxes
	database.insert_row("character_profile",
	{
		"char_id": inserted_char_id,
		"first_name": creation_first_name.text,
		"last_name": creation_last_name.text,
		"nickname": creation_nickname.text,
		"gender": "???"
	})

	main_tab.current_tab = MainTab.CHARACTERS


func _on_main_tab_tab_changed(tab):
	match tab:
		MainTab.CONNECTION:
			_on_connection_tab_entered()
		MainTab.CHARACTERS:
			_on_character_tab_entered()
		MainTab.CHARACTER_CREATION:
			_on_character_creation_tab_entered()
		_:
			popup_error("[ERROR] Invalid tab accessed!")
			return


func _on_connection_tab_entered():
	pass


func _on_character_tab_entered():
	var active_user_id := ConnectionInstance.get_active_user_id()

	if active_user_id == -1:
		popup_error("[ERROR] No session started!")
		return

	database.query_with_bindings("SELECT character.id, character_profile.first_name, character_profile.last_name, character_profile.nickname, character_profile.date, character_profile.location, character.experience
								FROM character
								LEFT JOIN character_profile
								ON character.id = character_profile.char_id
								WHERE character.user_id = ? ",[active_user_id])

	var result: Array = database.query_result
	if result.is_empty():
		character_select_create_tab.current_tab = CharacterSelectTab.NO_CHARACTERS_FOUND
		return
	else:
		character_select_create_tab.current_tab = CharacterSelectTab.ALL_CHARACTERS

		for child in creation_character_container.get_children():
			child.free()

	for row in result:
		var button = CHARACTER_BUTTON.instantiate()
		creation_character_container.add_child(button)
		button.update_button(row)


func _on_character_creation_tab_entered():
	pass
