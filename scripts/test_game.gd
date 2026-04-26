extends Node2D

@onready var memory_game = $MemoryGame

func _ready() -> void:
	# Os IDs devem existir em data/cards.json
	# Passe quantos pares quiser — todos precisam estar cadastrados no JSON
	# Só o gato para testar o seu spritesheet agora!
	var ids = ["gato","gato","gato","gato","gato","gato","gato","gato"]
	memory_game.setup_game(ids)
