extends Control

@onready var item_list = $HBoxContainer/ItemList
@onready var detail_label = $HBoxContainer/DetailPanel/VBoxContainer/ScrollContainer/DetailLabel
@onready var card_name_label = $HBoxContainer/DetailPanel/VBoxContainer/CardName

func _ready():
	_populate_list()
	_fix_hover_style()
	item_list.item_selected.connect(_on_item_list_item_selected)
	MusicManager.play_codex_music()

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
		var details = "[color=#0055aa]Espécie:[/color] %s\n" % card_data.get("species", "???")
		details += "[color=#0055aa]Nome Científico:[/color] %s\n" % card_data.get("scientific_name", "???")
		details += "[color=#0055aa]Onde vive:[/color] %s\n\n" % card_data.get("habitat", "???")
		details += "[color=#aa5500][Curiosidade]:[/color] %s\n\n" % card_data.get("curiosidade", "???")
		details += "[color=#aa5500][Super Poder]:[/color] %s\n\n" % card_data.get("super_poder", "???")
		details += "[color=#aa5500][O que gosta]:[/color] %s" % card_data.get("o_que_gosta", "???")
		detail_label.text = details

func _on_back_pressed():
	MusicManager.play_menu_music()
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
