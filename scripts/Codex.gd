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

func _ready():
	_is_web = OS.get_name() == "Web"
	_populate_list()
	_fix_hover_style()
	# This signal is also connected in the scene file; guard against double-connect.
	if not item_list.item_selected.is_connected(_on_item_list_item_selected):
		item_list.item_selected.connect(_on_item_list_item_selected)
	MusicManager.play_codex_music()
	animated_sprite.visible = false
	# Botões ficam escondidos até um animal ser selecionado
	speech_row.visible = false
	# Pré-carrega as vozes do navegador (Chrome precisa disso na primeira vez)
	if _is_web:
		JavaScriptBridge.eval("window.speechSynthesis.getVoices();")

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
		if _is_web:
			speech_row.visible = true

func _speak_animal(_card_data: Dictionary) -> void:
	pass # Mantido para compatibilidade — a fala agora só é acionada pelo botão

func _do_speak(text: String) -> void:
	if not _is_web:
		return
	# Passa o texto via variável global para evitar problemas de escape de aspas
	JavaScriptBridge.eval("window.__tts_text = %s;" % JSON.stringify(text))
	JavaScriptBridge.eval("""
		(function() {
			window.speechSynthesis.cancel();
			var utter = new SpeechSynthesisUtterance(window.__tts_text);
			utter.lang = 'pt-BR';
			utter.rate = 0.92;
			utter.pitch = 1.5;
			function trySpeak() {
				var voices = window.speechSynthesis.getVoices();
				var preferred = null;
				// Prioridade: Google pt-BR > qualquer pt-BR > qualquer pt
				preferred = voices.find(function(v) {
					return v.lang === 'pt-BR' && v.name.toLowerCase().includes('google');
				});
				if (!preferred) preferred = voices.find(function(v) { return v.lang === 'pt-BR'; });
				if (!preferred) preferred = voices.find(function(v) { return v.lang.startsWith('pt'); });
				if (preferred) utter.voice = preferred;
				window.speechSynthesis.speak(utter);
			}
			// Chrome carrega vozes de forma assincrona na primeira vez
			if (window.speechSynthesis.getVoices().length === 0) {
				window.speechSynthesis.addEventListener('voiceschanged', trySpeak, { once: true });
			} else {
				trySpeak();
			}
		})();
	""")

func _on_listen_pressed() -> void:
	if _last_speech_text != "":
		_do_speak(_last_speech_text)

func _on_stop_pressed() -> void:
	if not _is_web:
		return
	JavaScriptBridge.eval("window.speechSynthesis.cancel();")

func _on_back_pressed():
	# Para a fala ao sair da cena
	if _is_web:
		JavaScriptBridge.eval("window.speechSynthesis.cancel();")
	MusicManager.play_menu_music()
	SceneManager.goto_scene("res://scenes/Menu.tscn")

func _on_achievements_pressed():
	if _is_web:
		JavaScriptBridge.eval("window.speechSynthesis.cancel();")
	SceneManager.goto_scene("res://scenes/Achievements.tscn")
