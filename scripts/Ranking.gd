extends Control

@onready var difficulty_option: OptionButton = $Panel/VBoxContainer/DifficultyRow/DifficultyOption
@onready var entries_container: VBoxContainer = $Panel/VBoxContainer/Entries
@onready var title_label: Label = $Panel/VBoxContainer/Title

func _ready() -> void:
	MusicManager.play_ranking_music()
	_setup_difficulties()
	_refresh()

func _setup_difficulties() -> void:
	difficulty_option.clear()
	difficulty_option.add_item("Fácil", 0)
	difficulty_option.add_item("Médio", 1)
	difficulty_option.add_item("Difícil", 2)
	difficulty_option.select(_difficulty_to_index(GameManager.game_difficulty))

func _difficulty_to_index(d: String) -> int:
	match d:
		"medium": return 1
		"hard": return 2
		_: return 0

func _index_to_difficulty(i: int) -> String:
	match i:
		1: return "medium"
		2: return "hard"
		_: return "easy"

func _refresh() -> void:
	var diff := _index_to_difficulty(difficulty_option.selected)
	title_label.text = "Ranking (%s)" % _difficulty_label(diff)

	for c in entries_container.get_children():
		c.queue_free()

	var entries: Array = PlayerContext.get_ranking(diff)
	if entries.is_empty():
		var empty := Label.new()
		empty.text = "Ainda não tem resultados."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		entries_container.add_child(empty)
		return

	for i in range(entries.size()):
		var e: Dictionary = entries[i]
		var row := Label.new()
		var name := str(e.get("name", "Jogador"))
		var score := float(e.get("score", 0.0))
		row.text = "%d) %s — %d pts" % [i + 1, name, int(score)]
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		entries_container.add_child(row)

func _difficulty_label(d: String) -> String:
	match d:
		"medium": return "Médio"
		"hard": return "Difícil"
		_: return "Fácil"

func _on_difficulty_option_item_selected(_index: int) -> void:
	_refresh()

func _on_back_pressed() -> void:
	MusicManager.play_menu_music()
	SceneManager.goto_scene("res://scenes/Menu.tscn")

func _on_reset_pressed() -> void:
	PlayerContext.reset_ranking()
	_refresh()
