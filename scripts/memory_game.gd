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

var _all_selected_ids: Array = [] 
var sfx_player_correct: AudioStreamPlayer
var sfx_player_incorrect: AudioStreamPlayer
var sfx_player_victory: AudioStreamPlayer

func _ready():
	# Initialize SFX
	sfx_player_correct = AudioStreamPlayer.new()
	sfx_player_incorrect = AudioStreamPlayer.new()
	sfx_player_victory = AudioStreamPlayer.new()
	add_child(sfx_player_correct)
	add_child(sfx_player_incorrect)
	add_child(sfx_player_victory)
	
	sfx_player_correct.stream = load("res://sounds/correct.mp3")
	sfx_player_incorrect.stream = load("res://sounds/incorrect.mp3")
	sfx_player_victory.stream = load("res://sounds/victory.mp3")
	
	sfx_player_correct.volume_db = -10.0
	sfx_player_incorrect.volume_db = -10.0
	sfx_player_victory.volume_db = -10.0

	var all_ids = CardDatabase.get_all_ids()
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

func setup_game(elements: Array):
	victory_panel.visible = false
	message_label.text = ""
	elements_array = elements
	total_pairs = elements.size()
	matches_found = 0
	flipped_cards.clear()
	can_click = true
	
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
		matches_found += 1
		flipped_cards.clear()
		can_click = true
		
		if matches_found == total_pairs:
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

func _on_restart_button_pressed():
	MusicManager.play_music()
	setup_game(_all_selected_ids)

func _on_back_button_pressed():
	MusicManager.play_music()
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
