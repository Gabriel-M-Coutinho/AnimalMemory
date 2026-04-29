extends Control

@onready var item_list = $HBoxContainer/ItemList
@onready var detail_label = $HBoxContainer/DetailPanel/VBoxContainer/ContentHBox/ScrollContainer/DetailLabel
@onready var card_name_label = $HBoxContainer/DetailPanel/VBoxContainer/CardName
@onready var animated_sprite = $HBoxContainer/DetailPanel/VBoxContainer/ContentHBox/ImageColumn/ImageContainer/AnimatedSprite2D
@onready var image_container: Control = $HBoxContainer/DetailPanel/VBoxContainer/ContentHBox/ImageColumn/ImageContainer
@onready var speech_row: HBoxContainer = $HBoxContainer/DetailPanel/VBoxContainer/ContentHBox/ImageColumn/SpeechRow
@onready var listen_button: Button = $HBoxContainer/DetailPanel/VBoxContainer/ContentHBox/ImageColumn/SpeechRow/ListenButton
@onready var stop_button: Button = $HBoxContainer/DetailPanel/VBoxContainer/ContentHBox/ImageColumn/SpeechRow/StopButton

var _is_web: bool = false
var _last_speech_text: String = ""
var _current_id: String = ""
var narration_player: AudioStreamPlayer

func _ready():
	_is_web = OS.get_name() == "Web"
	_populate_list()
	_fix_hover_style()
	# This signal is also connected in the scene file; guard against double-connect.
	if not item_list.item_selected.is_connected(_on_item_list_item_selected):
		item_list.item_selected.connect(_on_item_list_item_selected)
	
	narration_player = AudioStreamPlayer.new()
	add_child(narration_player)
	
	MusicManager.play_codex_music()
	animated_sprite.visible = false
	# Botões agora mostrados para todos os sistemas
	speech_row.visible = false

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
			# Centraliza o sprite no container após o layout ser calculado
			await get_tree().process_frame
			animated_sprite.position = image_container.size / 2.0
		else:
			animated_sprite.visible = false
			
		var details = "[color=#0055aa]Espécie:[/color] %s\n" % card_data.get("species", "???")
		details += "[color=#0055aa]Nome Científico:[/color] %s\n" % card_data.get("scientific_name", "???")
		details += "[color=#0055aa]Onde vive:[/color] %s\n\n" % card_data.get("habitat", "???")
		details += "[color=#aa5500][Curiosidade]:[/color] %s\n\n" % card_data.get("curiosidade", "???")
		details += "[color=#aa5500][Super Poder]:[/color] %s\n\n" % card_data.get("super_poder", "???")
		details += "[color=#aa5500][O que gosta]:[/color] %s" % card_data.get("o_que_gosta", "???")
		detail_label.text = details
		
		# Prepara o texto da fala e mostra os botões (sem auto-play)
		var nome: String = card_data.get("name", "")
		var curiosidade: String = card_data.get("curiosidade", "")
		var super_poder: String = card_data.get("super_poder", "")
		var o_que_gosta: String = card_data.get("o_que_gosta", "")
		_last_speech_text = "%s! %s Que incrivel! Alem disso, %s E sabe o que mais? %s Que legal!" % [
			nome, curiosidade, super_poder, o_que_gosta
		]
		_current_id = selected_id
		speech_row.visible = true
		_play_animal_narration(selected_id)

func _play_animal_narration(id: String) -> void:
	var sound_file = id
	match id:
		"abelha": sound_file = "abelhas"
		"beijaflor": sound_file = "beijaflores"
		"cachorro": sound_file = "cachorros"
		"elefante": sound_file = "elefantes"
		"gato": sound_file = "gatos"
		"joaninha": sound_file = "joaninhas"
		"leao": sound_file = "leoes"
		"pato": sound_file = "patos"
	
	var path = "res://sounds/%s.mp3" % sound_file
	var stream = load(path)
	if stream:
		narration_player.stream = stream
		narration_player.play()

func _speak_animal(_card_data: Dictionary) -> void:
	pass # Mantido para compatibilidade

func _on_listen_pressed() -> void:
	if _current_id != "":
		_play_animal_narration(_current_id)

func _on_stop_pressed() -> void:
	if narration_player and narration_player.playing:
		narration_player.stop()

func _on_back_pressed():
	if narration_player and narration_player.playing:
		narration_player.stop()
	MusicManager.play_menu_music()
	SceneManager.goto_scene("res://scenes/Menu.tscn")

func _on_achievements_pressed():
	if narration_player and narration_player.playing:
		narration_player.stop()
	SceneManager.goto_scene("res://scenes/Achievements.tscn")
