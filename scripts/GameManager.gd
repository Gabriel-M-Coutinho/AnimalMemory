extends Node

func _ready():
	# Força a orientação horizontal se o dispositivo suportar
	if DisplayServer.has_feature(DisplayServer.FEATURE_ORIENTATION):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)

var game_difficulty: String = "easy"
var cards_to_spawn: int = 4

func set_difficulty(difficulty: String):
	game_difficulty = difficulty
	match difficulty:
		"easy":
			cards_to_spawn = 4
		"medium":
			cards_to_spawn = 8
		"hard":
			cards_to_spawn = 16
