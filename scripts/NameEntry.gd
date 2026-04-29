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
	name_edit.focus_entered.connect(_on_name_edit_focus_entered)
	name_edit.text_changed.connect(_on_name_edit_text_changed)
	
	if default_index != -1:
		user_select.selected = default_index
		_on_user_selected(default_index)
	
	# Always grab focus at start with a small delay for reliability
	await get_tree().process_frame
	name_edit.grab_focus()
	# For some environments (mobile/web), a bit more time helps
	await get_tree().create_timer(0.1).timeout
	if is_inside_tree() and not name_edit.has_focus():
		name_edit.grab_focus()

func _on_user_selected(index: int) -> void:
	# Now the box is always editable, selecting just pre-fills it
	name_edit.editable = true
	if index == 0:
		name_edit.text = ""
	else:
		name_edit.text = existing_users[index - 1]
	
	name_edit.grab_focus()

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

func _on_name_edit_focus_entered() -> void:
	# Select all text so it's easy to overwrite if they want a new player
	name_edit.select_all()

func _on_name_edit_text_changed(new_text: String) -> void:
	# If the user is typing something that doesn't match the selected profile,
	# switch the dropdown to "Novo Usuário..." automatically
	if user_select.selected != 0:
		var selected_name = existing_users[user_select.selected - 1]
		if new_text != selected_name:
			user_select.selected = 0
