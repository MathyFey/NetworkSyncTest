extends Button

const MAX_TEXT_LENGTH := 10

var character_info: Dictionary = {}

@onready var button_first_name: Label = $MarginContainer/VBoxContainer/HBoxContainer2/HBoxContainer/FirstName
@onready var button_last_name: Label = $MarginContainer/VBoxContainer/HBoxContainer2/HBoxContainer/LastName
@onready var button_nickname: Label = $MarginContainer/VBoxContainer/HBoxContainer2/Nickname
@onready var button_date: Label = $MarginContainer/VBoxContainer/HBoxContainer3/HBoxContainer/Date
@onready var button_location: Label = $MarginContainer/VBoxContainer/HBoxContainer3/HBoxContainer2/Location
@onready var button_level: Label = $MarginContainer/VBoxContainer/HBoxContainer4/HBoxContainer/Level

func update_button(info_dict: Dictionary) -> void:
    var first_name: String = "Undefined"
    var last_name: String = "Undefined"
    var nickname: String = "Undefined"
    var date: String = "????/??/??"
    var location: String = "????"
    var experience: int = 0

    if info_dict["first_name"] != null:
        first_name = info_dict["first_name"]
    if info_dict["last_name"] != null:
        last_name = info_dict["last_name"]
    if info_dict["nickname"] != null:
        nickname = info_dict["nickname"]
    if info_dict["date"] != null:
        date = info_dict["date"]
    if info_dict["location"] != null:
        location = info_dict["location"]
    if info_dict["experience"] != null:
        experience = info_dict["experience"]

    # Update button texts
    button_first_name.text = first_name.capitalize().left(MAX_TEXT_LENGTH)
    button_last_name.text = last_name.capitalize().left(MAX_TEXT_LENGTH)
    button_nickname.text = str("(", nickname, ")").capitalize().left(MAX_TEXT_LENGTH)
    button_date.text = date.capitalize()
    button_location.text = location.capitalize()
    button_level.text = str(experience / 100.0).capitalize()

    character_info = info_dict


func _on_pressed():
    #TODO: Find a better way to handle character sessions
    ConnectionInstance.set_active_character_for_session(character_info)
    get_tree().change_scene_to_file("res://playground/dev.tscn")
