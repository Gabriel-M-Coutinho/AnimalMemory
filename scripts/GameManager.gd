extends Node

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
