extends Node

var bg_music_player: AudioStreamPlayer
var current_track: String = ""

func _ready():
	bg_music_player = AudioStreamPlayer.new()
	add_child(bg_music_player)
	play_menu_music()

func play_menu_music():
	_play_track("res://sounds/menu_background.mp3")

func play_codex_music():
	_play_track("res://sounds/codex_sound.mp3")

func _play_track(path: String):
	if current_track == path:
		return
	
	var stream = load(path)
	if stream:
		bg_music_player.stop()
		bg_music_player.stream = stream
		bg_music_player.volume_db = -12.0
		bg_music_player.play()
		current_track = path

func stop_music():
	bg_music_player.stop()

func play_music():
	if not bg_music_player.playing:
		bg_music_player.play()
