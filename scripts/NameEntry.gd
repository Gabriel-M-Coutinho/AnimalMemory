extends Control

@onready var name_edit: LineEdit = $Panel/MarginContainer/VBoxContainer/NameEdit
@onready var error_label: Label = $Panel/MarginContainer/VBoxContainer/ErrorLabel
@onready var user_select: OptionButton = $Panel/MarginContainer/VBoxContainer/UserSelect

var existing_users: Array = []

func _ready() -> void:
	error_label.text = ""
	existing_users = PlayerContext.get_all_users()
	
	user_select.clear()
	user_select.add_item("Novo Usuário...")
	for u in existing_users:
		user_select.add_item(u)
	
	user_select.item_selected.connect(_on_user_selected)
	name_edit.grab_focus()

func _on_user_selected(index: int) -> void:
	if index == 0:
		name_edit.text = ""
		name_edit.editable = true
		name_edit.grab_focus()
	else:
		name_edit.text = existing_users[index - 1]
		name_edit.editable = false

func _on_continue_pressed() -> void:
	var name_input = name_edit.text.strip_edges()
	if name_input == "":
		error_label.text = "Por favor, insira um nome."
		return
	
	if user_select.selected == 0 and name_input in existing_users:
		error_label.text = "Nome já existe. Veja a lista."
		return
		
	PlayerContext.register_user(name_input)
	PlayerContext.set_player_name(name_input)
	SceneManager.goto_scene("res://scenes/Menu.tscn")

func _on_name_edit_text_submitted(_new_text: String) -> void:
	_on_continue_pressed()
