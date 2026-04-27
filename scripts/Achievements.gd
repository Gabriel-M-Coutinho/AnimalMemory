extends Control

@onready var list: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/List

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	for c in list.get_children():
		c.queue_free()

	var def_icon := load("res://icon.svg") as Texture2D
	var star_icon := load("res://sprites/achievement_star.jpg") as Texture2D
	var medal_icon := load("res://sprites/achievement_medal.jpg") as Texture2D
	var trophy_icon := load("res://sprites/achievement_trophy.jpg") as Texture2D
	var crown_icon := load("res://sprites/achievement_crown.jpg") as Texture2D
	var brain_icon := load("res://sprites/achievement_brain.jpg") as Texture2D

	_add_title("Conquistas gerais")
	var wins := ProgressManager.get_total_wins()
	_add_check("Primeira vitória", wins >= 1, "%d/1" % wins, star_icon)
	_add_check("5 vitórias", wins >= 5, "%d/5" % wins, medal_icon)
	_add_check("10 vitórias", wins >= 10, "%d/10" % wins, trophy_icon)

	_add_spacer()
	_add_title("Sem usar dica")
	var no_hint := ProgressManager.get_wins_no_hint()
	_add_check("Ganhar sem dica (1x)", no_hint >= 1, "%d/1" % no_hint, brain_icon)
	_add_check("Ganhar sem dica (5x)", no_hint >= 5, "%d/5" % no_hint, brain_icon)

	_add_spacer()
	_add_title("Colecionáveis (por animal)")
	var ids := CardDatabase.get_all_ids()
	ids.sort()
	for id in ids:
		var card_data = CardDatabase.get_card(id)
		var name: String = ""
		var tex: Texture2D = null
		if card_data:
			name = str(card_data.get("name", id))
			if card_data.has("sprite"):
				var base_tex = load(card_data["sprite"]) as Texture2D
				if base_tex:
					var atlas = AtlasTexture.new()
					atlas.atlas = base_tex
					var fw = card_data.get("frame_width", 64)
					var fh = card_data.get("frame_height", 64)
					atlas.region = Rect2(0, 0, fw, fh)
					tex = atlas
		else:
			name = str(id)
		var count: int = ProgressManager.get_card_count(id)
		var milestone_icon = tex
		if count >= 1:
			milestone_icon = load("res://sprites/milestone_bronze.jpg")
		_add_progress("%s — %d/10" % [name, count], count >= 10, milestone_icon if milestone_icon else def_icon)

func _add_title(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(lbl)

func _add_check(text: String, ok: bool, progress: String, icon: Texture2D = null) -> void:
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	
	var tex_rect := TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(64, 64)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if icon:
		tex_rect.texture = icon
	if not ok:
		tex_rect.modulate = Color(0.2, 0.2, 0.2, 1.0)
	hbox.add_child(tex_rect)
	
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.text = ("%s  (%s)" % [text, progress]) if not ok else ("%s  (OK)" % text)
	if not ok:
		lbl.modulate = Color(0.7, 0.7, 0.7, 1.0)
	hbox.add_child(lbl)
	
	list.add_child(hbox)

func _add_progress(text: String, ok: bool, icon: Texture2D = null) -> void:
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	
	var tex_rect := TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(64, 64)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if icon:
		tex_rect.texture = icon
	if not ok:
		tex_rect.modulate = Color(0.2, 0.2, 0.2, 1.0)
	hbox.add_child(tex_rect)

	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.text = text + ("  (OK)" if ok else "")
	if not ok:
		lbl.modulate = Color(0.7, 0.7, 0.7, 1.0)
	hbox.add_child(lbl)
	
	list.add_child(hbox)

func _add_spacer() -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, 12)
	list.add_child(s)

func _on_back_pressed() -> void:
	SceneManager.goto_scene("res://scenes/Menu.tscn")
