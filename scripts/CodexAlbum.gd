extends Control

@export var columns_desktop: int = 4
@export var columns_mobile: int = 3

@onready var grid: GridContainer = $Panel/VBoxContainer/ScrollContainer/Grid
@onready var detail_panel: PanelContainer = $DetailPanel
@onready var detail_name: Label = $DetailPanel/Margin/VBoxContainer/CardName
@onready var detail_sprite: AnimatedSprite2D = $DetailPanel/Margin/VBoxContainer/ContentHBox/ImageContainer/AnimatedSprite2D
@onready var detail_label: RichTextLabel = $DetailPanel/Margin/VBoxContainer/ContentHBox/ScrollContainer/DetailLabel
@onready var detail_progress: Label = $DetailPanel/Margin/VBoxContainer/ProgressLabel

var _current_id: String = ""

func _ready() -> void:
	MusicManager.play_codex_music()
	_build_grid()
	_hide_detail()

func _build_grid() -> void:
	grid.columns = columns_mobile if (OS.has_feature("mobile") or OS.has_feature("web")) else columns_desktop
	for c in grid.get_children():
		c.queue_free()

	var ids := CardDatabase.get_all_ids()
	ids.sort()

	for id in ids:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(220, 220)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(func(): _on_card_pressed(id))

		var vb := VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vb.add_theme_constant_override("separation", 6)
		btn.add_child(vb)

		var tex_rect := TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(160, 160)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vb.add_child(tex_rect)

		var name_lbl := Label.new()
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vb.add_child(name_lbl)

		var unlocked := ProgressManager.is_unlocked(id)
		if unlocked:
			var card_data = CardDatabase.get_card(id)
			name_lbl.text = str(card_data.get("name", id)) if card_data else id
			tex_rect.texture = _get_card_preview_texture(id)
			btn.disabled = false
		else:
			name_lbl.text = "???"
			tex_rect.texture = null
			btn.disabled = false # allow peek at locked entry (still kid-friendly)

		grid.add_child(btn)

func _get_card_preview_texture(id: String) -> Texture2D:
	var frames: SpriteFrames = CardDatabase.get_sprite_frames(id)
	if frames == null:
		return null
	if frames.has_animation("idle") and frames.get_frame_count("idle") > 0:
		return frames.get_frame_texture("idle", 0)
	if frames.has_animation("movement") and frames.get_frame_count("movement") > 0:
		return frames.get_frame_texture("movement", 0)
	# Fallback: any non-cardback animation
	for anim in frames.get_animation_names():
		if String(anim) == "cardback":
			continue
		if frames.get_frame_count(anim) > 0:
			return frames.get_frame_texture(anim, 0)
	return null

func _on_card_pressed(id: String) -> void:
	_current_id = id
	_show_detail(id)

func _show_detail(id: String) -> void:
	detail_panel.visible = true
	var unlocked := ProgressManager.is_unlocked(id)
	var card_data = CardDatabase.get_card(id)

	if unlocked and card_data:
		detail_name.text = str(card_data.get("name", id))
		detail_label.text = _build_details_bbcode(card_data)
	else:
		detail_name.text = "???"
		detail_label.text = "Jogue para desbloquear esta carta!"

	var frames: SpriteFrames = CardDatabase.get_sprite_frames(id)
	if frames:
		detail_sprite.sprite_frames = frames
		detail_sprite.visible = unlocked
		if unlocked:
			if frames.has_animation("movement"):
				detail_sprite.play("movement")
			elif frames.has_animation("idle"):
				detail_sprite.play("idle")

	var count := ProgressManager.get_card_count(id)
	detail_progress.text = "Encontrado: %dx" % count

func _build_details_bbcode(card_data: Dictionary) -> String:
	var details = "[color=#0055aa]Espécie:[/color] %s\n" % card_data.get("species", "???")
	details += "[color=#0055aa]Nome Científico:[/color] %s\n" % card_data.get("scientific_name", "???")
	details += "[color=#0055aa]Onde vive:[/color] %s\n\n" % card_data.get("habitat", "???")
	details += "[color=#aa5500][Curiosidade]:[/color] %s\n\n" % card_data.get("curiosidade", "???")
	details += "[color=#aa5500][Super Poder]:[/color] %s\n\n" % card_data.get("super_poder", "???")
	details += "[color=#aa5500][O que gosta]:[/color] %s" % card_data.get("o_que_gosta", "???")
	return details

func _hide_detail() -> void:
	detail_panel.visible = false
	_current_id = ""

func _on_close_detail_pressed() -> void:
	_hide_detail()

func _on_back_pressed() -> void:
	MusicManager.play_menu_music()
	SceneManager.goto_scene("res://scenes/Menu.tscn")
