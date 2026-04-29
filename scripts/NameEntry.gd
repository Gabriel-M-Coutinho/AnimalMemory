extends Control

@onready var name_edit: LineEdit = $Panel/MarginContainer/VBoxContainer/NameEdit
@onready var error_label: Label = $Panel/MarginContainer/VBoxContainer/ErrorLabel
@onready var user_select: OptionButton = $Panel/MarginContainer/VBoxContainer/UserSelect

var existing_users: Array = []

func _ready() -> void:
	if MusicManager.has_method("play_menu_music"):
		MusicManager.play_menu_music()
	error_label.text = ""
	existing_users = PlayerContext.get_all_users()
	
	user_select.clear()
	user_select.add_item("Novo Usuário...")
	
	var default_index = -1
	for i in range(existing_users.size()):
		var u = existing_users[i]
		user_select.add_item(u)
		if u == PlayerContext.DEFAULT_PLAYER_NAME:
			default_index = i + 1
	
	user_select.item_selected.connect(_on_user_selected)
	
	if default_index != -1:
		user_select.selected = default_index
		_on_user_selected(default_index)
	else:
		name_edit.grab_focus()

func _on_user_selected(index: int) -> void:
	if index == 0:
		name_edit.text = ""
		name_edit.editable = true
		name_edit.grab_focus()
		# For mobile web, sometimes we need to wait a bit
		await get_tree().create_timer(0.1).timeout
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
