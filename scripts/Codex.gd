extends Control

@onready var item_list = $HBoxContainer/ItemList
@onready var detail_label = $HBoxContainer/DetailPanel/VBoxContainer/ContentHBox/ScrollContainer/DetailLabel
@onready var card_name_label = $HBoxContainer/DetailPanel/VBoxContainer/CardName
@onready var animated_sprite = $HBoxContainer/DetailPanel/VBoxContainer/ContentHBox/ImageContainer/AnimatedSprite2D

func _ready():
	_populate_list()
	_fix_hover_style()
	# This signal is also connected in the scene file; guard against double-connect.
	if not item_list.item_selected.is_connected(_on_item_list_item_selected):
		item_list.item_selected.connect(_on_item_list_item_selected)
	MusicManager.play_codex_music()
	# Esconde o sprite até algo ser selecionado
	animated_sprite.visible = false

func _fix_hover_style():
	# Sobrescreve o fundo do hover com azul semitransparente,
	# evitando o branco que apaga o texto no item selecionado
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0, 0.35, 0.85, 0.45)  # Azul levemente diferente do selected
	hover_style.set_corner_radius_all(4)
	item_list.add_theme_stylebox_override("hovered", hover_style)

	# Cor do texto no hover — branco para contrastar com o fundo azul
	item_list.add_theme_color_override("font_hovered_color", Color.WHITE)

func _populate_list():
	item_list.clear()
	var ids = CardDatabase.get_all_ids()
	for id in ids:
		var card_data = CardDatabase.get_card(id)
		if card_data:
			item_list.add_item(card_data.get("name", id))

func _on_item_list_item_selected(index):
	var ids = CardDatabase.get_all_ids()
	var selected_id = ids[index]
	var card_data = CardDatabase.get_card(selected_id)

	if card_data:
		card_name_label.text = card_data.get("name", "Desconhecido")
		
		# Atualiza a animação
		var sprite_frames = CardDatabase.get_sprite_frames(selected_id)
		if sprite_frames:
			animated_sprite.sprite_frames = sprite_frames
			animated_sprite.visible = true
			if sprite_frames.has_animation("movement"):
				animated_sprite.play("movement")
			else:
				animated_sprite.play("idle")
		else:
			animated_sprite.visible = false
			
		var details = "[color=#0055aa]Espécie:[/color] %s\n" % card_data.get("species", "???")
		details += "[color=#0055aa]Nome Científico:[/color] %s\n" % card_data.get("scientific_name", "???")
		details += "[color=#0055aa]Onde vive:[/color] %s\n\n" % card_data.get("habitat", "???")
		details += "[color=#aa5500][Curiosidade]:[/color] %s\n\n" % card_data.get("curiosidade", "???")
		details += "[color=#aa5500][Super Poder]:[/color] %s\n\n" % card_data.get("super_poder", "???")
		details += "[color=#aa5500][O que gosta]:[/color] %s" % card_data.get("o_que_gosta", "???")
		detail_label.text = details

func _on_back_pressed():
	MusicManager.play_menu_music()
	SceneManager.goto_scene("res://scenes/Menu.tscn")

func _on_achievements_pressed():
	SceneManager.goto_scene("res://scenes/Achievements.tscn")
