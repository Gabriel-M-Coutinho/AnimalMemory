extends Control

@export var card_scene: PackedScene
@export var grid_container_path: NodePath = "CenterContainer/GridContainer"

var elements_array: Array = []
var flipped_cards: Array = []
var matches_found: int = 0
var total_pairs: int = 0
var can_click: bool = true

@onready var grid_container = get_node(grid_container_path)
@onready var message_label = $MessageLabel
@onready var victory_panel = $VictoryPanel
@onready var lose_panel = $LosePanel
@onready var timer_label: Label = $TimerLabel
@onready var victory_sub_label: Label = $VictoryPanel/VBoxContainer/SubLabel
@onready var hint_button: Button = $HintButton

var _all_selected_ids: Array = [] 
var sfx_player_correct: AudioStreamPlayer
var sfx_player_incorrect: AudioStreamPlayer
var sfx_player_victory: AudioStreamPlayer
var sfx_player_fail: AudioStreamPlayer

var time_left: float = 30.0
var _ended: bool = false
var _hint_cooldown_left: float = 0.0
const HINT_COOLDOWN_SECONDS := 5.0
var _hints_used_this_run: int = 0

func _ready():
	# Initialize SFX
	sfx_player_correct = AudioStreamPlayer.new()
	sfx_player_incorrect = AudioStreamPlayer.new()
	sfx_player_victory = AudioStreamPlayer.new()
	sfx_player_fail = AudioStreamPlayer.new()
	add_child(sfx_player_correct)
	add_child(sfx_player_incorrect)
	add_child(sfx_player_victory)
	add_child(sfx_player_fail)
	
	sfx_player_correct.stream = load("res://sounds/correct.mp3")
	sfx_player_incorrect.stream = load("res://sounds/incorrect.mp3")
	sfx_player_victory.stream = load("res://sounds/victory.mp3")
	sfx_player_fail.stream = load("res://sounds/sound_fail.mp3")
	
	sfx_player_correct.volume_db = -10.0
	sfx_player_incorrect.volume_db = -10.0
	sfx_player_victory.volume_db = -10.0
	sfx_player_fail.volume_db = -10.0

	_start_timer()

	randomize()
	var all_ids = CardDatabase.get_all_ids()
	all_ids.shuffle()
	
	var cards_needed = GameManager.cards_to_spawn / 2
	var selected_elements = []
	
	for i in range(cards_needed):
		selected_elements.append(all_ids[i % all_ids.size()])
	
	_all_selected_ids = selected_elements
	
	# Adjust grid columns based on difficulty
	match GameManager.game_difficulty:
		"easy":
			grid_container.columns = 2
		"medium":
			grid_container.columns = 4
		"hard":
			grid_container.columns = 8
			
	setup_game(selected_elements)

func _start_timer() -> void:
	_ended = false
	time_left = GameManager.time_limit_seconds
	_update_timer_label()
	set_process(true)

func _process(delta: float) -> void:
	if _ended:
		return
	if _hint_cooldown_left > 0.0:
		_hint_cooldown_left = maxf(0.0, _hint_cooldown_left - delta)
		_update_hint_button()
	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		_update_timer_label()
		_trigger_lose()
		return
	_update_timer_label()

func _update_timer_label() -> void:
	if timer_label:
		timer_label.text = "Tempo: %d" % int(ceil(time_left))
		if time_left <= 10.0:
			timer_label.add_theme_color_override("font_color", Color.RED)
		else:
			timer_label.remove_theme_color_override("font_color")

func setup_game(elements: Array):
	victory_panel.visible = false
	lose_panel.visible = false
	message_label.text = ""
	elements_array = elements
	total_pairs = elements.size()
	matches_found = 0
	flipped_cards.clear()
	can_click = true
	_start_timer()
	_hint_cooldown_left = 0.0
	_hints_used_this_run = 0
	_update_hint_button()
	
	if grid_container:
		for child in grid_container.get_children():
			child.queue_free()
		
		var game_deck = []
		for item in elements:
			game_deck.append(item)
			game_deck.append(item)
		
		game_deck.shuffle()
		
		for item in game_deck:
			if card_scene:
				var card = card_scene.instantiate()
				grid_container.add_child(card)
				card.setup(item)
				card.card_clicked.connect(_on_card_clicked)

		# Pré-visualização apenas no modo DIFÍCIL
		if GameManager.game_difficulty == "hard":
			can_click = false
			await get_tree().create_timer(0.8).timeout
			for card in grid_container.get_children():
				if card.has_method("flip"):
					card.flip(true)
			
			await get_tree().create_timer(1.5).timeout
			
			for card in grid_container.get_children():
				if card.has_method("flip"):
					card.flip(false)
			
			await get_tree().create_timer(0.5).timeout
			can_click = true
		else:
			can_click = true

func show_message(text: String, color: Color = Color.WHITE, duration: float = 1.0):
	message_label.text = text
	message_label.add_theme_color_override("font_color", color)
	await get_tree().create_timer(duration).timeout
	if message_label.text == text:
		message_label.text = ""

func _on_card_clicked(card):
	if not can_click or card in flipped_cards:
		return
	
	card.flip(true)
	flipped_cards.append(card)
	
	if flipped_cards.size() == 2:
		_check_match()

func _check_match():
	can_click = false
	var card1 = flipped_cards[0]
	var card2 = flipped_cards[1]
	
	if card1.card_id == card2.card_id:
		show_message("Muito bem!", Color.GREEN_YELLOW)
		sfx_player_correct.play()
		card1.is_matched = true
		card2.is_matched = true
		card1.update_visuals()
		card2.update_visuals()
		ProgressManager.record_pair_found(card1.card_id)
		matches_found += 1
		flipped_cards.clear()
		can_click = true
		
		if matches_found == total_pairs:
			_end_game(true)
			await get_tree().create_timer(0.5).timeout
			MusicManager.stop_music()
			sfx_player_victory.play()
			victory_panel.visible = true
	else:
		show_message("Tente de novo!", Color.CORAL)
		sfx_player_incorrect.play()
		await get_tree().create_timer(1.0).timeout
		card1.flip(false)
		card2.flip(false)
		flipped_cards.clear()
		can_click = true

func _end_game(won: bool) -> void:
	if _ended:
		return
	_ended = true
	set_process(false)
	can_click = false
	if won:
		var score := _compute_score()
		ProgressManager.record_win(_hints_used_this_run == 0)
		var rank := PlayerContext.add_win_score(GameManager.game_difficulty, score)
		if victory_sub_label:
			if rank > 0:
				var bonus_text := "Bônus (sem dica)!" if _hints_used_this_run == 0 else ""
				victory_sub_label.text = "Você fez %d pontos! %s\nSua posição no ranking: %dº" % [int(score), bonus_text, rank]
			else:
				victory_sub_label.text = "Você fez %d pontos!" % int(score)

func _trigger_lose() -> void:
	_end_game(false)
	MusicManager.stop_music()
	sfx_player_fail.play()
	lose_panel.visible = true

func _update_hint_button() -> void:
	if not hint_button:
		return
	if _ended:
		hint_button.disabled = true
		return
	if _hint_cooldown_left > 0.0:
		hint_button.disabled = true
		hint_button.text = "Dica (%.0fs)" % ceil(_hint_cooldown_left)
	else:
		hint_button.disabled = false
		hint_button.text = "Dica"

func _on_hint_button_pressed() -> void:
	if _ended:
		return
	if _hint_cooldown_left > 0.0:
		return
	if flipped_cards.size() > 0:
		return
	await _use_hint()

func _use_hint() -> void:
	if not grid_container:
		return
	_hint_cooldown_left = HINT_COOLDOWN_SECONDS
	_hints_used_this_run += 1
	ProgressManager.record_hint_used()
	_update_hint_button()
	can_click = false

	var candidates: Array = []
	for c in grid_container.get_children():
		if c == null:
			continue
		if c.get("is_matched"):
			continue
		if c.get("is_flipped"):
			continue
		candidates.append(c)

	if candidates.size() < 2:
		can_click = true
		return

	candidates.shuffle()
	var a = candidates[0]
	var b = candidates[1]
	a.flip(true)
	b.flip(true)
	await get_tree().create_timer(1.0).timeout
	if not a.get("is_matched"):
		a.flip(false)
	if not b.get("is_matched"):
		b.flip(false)
	can_click = true

func _compute_score() -> float:
	# Pontuação simples e “infantil”:
	# - Base = tempo restante * 100
	# - Bônus se não usar dica: +500
	var base := int(round(time_left * 100.0))
	var bonus := 500 if _hints_used_this_run == 0 else 0
	return float(maxi(0, base + bonus))

func _on_restart_button_pressed():
	MusicManager.play_music()
	setup_game(_all_selected_ids)

func _on_back_button_pressed():
	MusicManager.play_music()
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
