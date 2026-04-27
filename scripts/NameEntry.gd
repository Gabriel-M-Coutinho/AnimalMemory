extends Control

@onready var name_edit: LineEdit = $Panel/VBoxContainer/NameEdit
@onready var error_label: Label = $Panel/VBoxContainer/ErrorLabel

func _ready() -> void:
	error_label.text = ""
	name_edit.grab_focus()

func _on_continue_pressed() -> void:
	PlayerContext.set_player_name(name_edit.text)
	SceneManager.goto_scene("res://scenes/Menu.tscn")

func _on_name_edit_text_submitted(_new_text: String) -> void:
	_on_continue_pressed()
