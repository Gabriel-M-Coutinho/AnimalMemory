extends Control

@onready var list: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/List

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	for c in list.get_children():
		c.queue_free()

	_add_title("Conquistas gerais")
	var wins := ProgressManager.get_total_wins()
	_add_check("Primeira vitória", wins >= 1, "%d/1" % wins)
	_add_check("5 vitórias", wins >= 5, "%d/5" % wins)
	_add_check("10 vitórias", wins >= 10, "%d/10" % wins)

	_add_spacer()
	_add_title("Sem usar dica")
	var no_hint := ProgressManager.get_wins_no_hint()
	_add_check("Ganhar sem dica (1x)", no_hint >= 1, "%d/1" % no_hint)
	_add_check("Ganhar sem dica (5x)", no_hint >= 5, "%d/5" % no_hint)

	_add_spacer()
	_add_title("Colecionáveis (por animal)")
	var ids := CardDatabase.get_all_ids()
	ids.sort()
	for id in ids:
		var card_data = CardDatabase.get_card(id)
		var name: String = ""
		if card_data:
			name = str(card_data.get("name", id))
		else:
			name = str(id)
		var count: int = ProgressManager.get_card_count(id)
		_add_progress("%s — %d/10" % [name, count], count >= 10)

func _add_title(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(lbl)

func _add_check(text: String, ok: bool, progress: String) -> void:
	var lbl := Label.new()
	lbl.text = ("%s  (%s)" % [text, progress]) if not ok else ("%s  (OK)" % text)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(lbl)

func _add_progress(text: String, ok: bool) -> void:
	var lbl := Label.new()
	lbl.text = text + ("  (OK)" if ok else "")
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(lbl)

func _add_spacer() -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, 12)
	list.add_child(s)

func _on_back_pressed() -> void:
	SceneManager.goto_scene("res://scenes/Menu.tscn")
