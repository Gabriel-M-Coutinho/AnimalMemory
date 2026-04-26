extends Control

func _on_easy_pressed():
	GameManager.set_difficulty("easy")
	SceneManager.goto_scene("res://scenes/memory_game.tscn")

func _on_medium_pressed():
	GameManager.set_difficulty("medium")
	SceneManager.goto_scene("res://scenes/memory_game.tscn")

func _on_hard_pressed():
	GameManager.set_difficulty("hard")
	SceneManager.goto_scene("res://scenes/memory_game.tscn")

func _on_codex_pressed():
	SceneManager.goto_scene("res://scenes/Codex.tscn")

func _on_exit_pressed():
	get_tree().quit()
