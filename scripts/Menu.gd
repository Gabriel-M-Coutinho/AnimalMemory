extends Control

@onready var ranking_text: RichTextLabel = $RankingPanel/MarginContainer/VBoxContainer/RankingText
@onready var difficulty_option: OptionButton = $RankingPanel/MarginContainer/VBoxContainer/DifficultyOption
@onready var page_label: Label = $RankingPanel/MarginContainer/VBoxContainer/PaginationRow/PageLabel

var current_ranking_page: int = 0
var current_difficulty_index: int = 0

func _ready() -> void:
	difficulty_option.add_item("Fácil", 0)
	difficulty_option.add_item("Médio", 1)
	difficulty_option.add_item("Difícil", 2)
	_refresh_ranking(0)

func _on_difficulty_option_item_selected(index: int) -> void:
	_refresh_ranking(index)

func _refresh_ranking(index: int) -> void:
	current_difficulty_index = index
	current_ranking_page = 0
	_update_ranking_display()

func _update_ranking_display() -> void:
	var diff_map = {0: "easy", 1: "medium", 2: "hard"}
	var diff = diff_map[current_difficulty_index]
	var text = ""
	
	var entries = PlayerContext.get_ranking(diff)
	var max_pages = max(1, ceil(entries.size() / 5.0))
	
	if current_ranking_page >= max_pages:
		current_ranking_page = max_pages - 1
	if current_ranking_page < 0:
		current_ranking_page = 0
		
	if page_label:
		page_label.text = "%d/%d" % [current_ranking_page + 1, max_pages]
	
	if entries.is_empty():
		text += "[center][color=white]Ainda não há resultados.[/color][/center]"
	else:
		var start_idx = current_ranking_page * 5
		var end_idx = min(start_idx + 5, entries.size())
		for i in range(start_idx, end_idx):
			var e = entries[i]
			var score = int(float(e.get("score", 0.0)))
			text += "[center][color=white]%d) %s - %d pts[/color][/center]\n\n" % [i + 1, e.get("name", "Jogador"), score]
	
	if ranking_text:
		ranking_text.text = text

@onready var clear_popup: ColorRect = $ClearRankingPopup

func _on_prev_page_pressed() -> void:
	current_ranking_page -= 1
	_update_ranking_display()

func _on_next_page_pressed() -> void:
	current_ranking_page += 1
	_update_ranking_display()

func _on_clear_ranking_pressed() -> void:
	if clear_popup:
		clear_popup.show()

func _on_confirm_clear_pressed() -> void:
	var diff_map = {0: "easy", 1: "medium", 2: "hard"}
	var diff = diff_map[current_difficulty_index]
	PlayerContext.clear_ranking(diff)
	current_ranking_page = 0
	_update_ranking_display()
	if clear_popup:
		clear_popup.hide()

func _on_cancel_clear_pressed() -> void:
	if clear_popup:
		clear_popup.hide()

func _on_easy_pressed():
	GameManager.set_difficulty("easy")
	SceneManager.goto_scene("res://scenes/memory_game.tscn")

func _on_medium_pressed():
	GameManager.set_difficulty("medium")
	SceneManager.goto_scene("res://scenes/memory_game.tscn")

func _on_hard_pressed():
	GameManager.set_difficulty("hard")
	SceneManager.goto_scene("res://scenes/memory_game.tscn")

func _on_codex_pressed():
	SceneManager.goto_scene("res://scenes/Codex.tscn")

func _on_logout_pressed():
	PlayerContext.set_player_name("")
	SceneManager.goto_scene("res://scenes/NameEntry.tscn")

func _on_exit_pressed():
	get_tree().quit()
