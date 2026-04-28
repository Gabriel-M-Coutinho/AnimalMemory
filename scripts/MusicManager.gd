extends Node

var bg_music_player: AudioStreamPlayer
var current_track: String = ""

func _ready():
	bg_music_player = AudioStreamPlayer.new()
	add_child(bg_music_player)
	play_menu_music()

func play_menu_music():
	# Menu music tends to be perceived louder; keep it slightly lower.
	_play_track("res://sounds/menu_background.mp3", -16.0, 0.0)

func play_codex_music():
	_play_track("res://sounds/codex_sound.mp3", -12.0, 0.0)

func play_ranking_music():
	# Start at 25.04 seconds.
	_play_track("res://sounds/soundtrack_ranking.mp3", -12.0, 25.04, 0.0, true)

func play_achievements_music():
	_play_track("res://sounds/soundtrack_achievements.mp3", -12.0, 0.0)

func _play_track(
	path: String,
	volume_db: float = -12.0,
	start_seconds: float = 0.0,
	fade_in_seconds: float = 0.0,
	force_restart: bool = false
):
	if current_track == path and not force_restart:
		return
	
	var stream = load(path)
	if stream:
		bg_music_player.stop()
		bg_music_player.stream = stream
		bg_music_player.volume_db = volume_db
		bg_music_player.play(maxf(start_seconds, 0.0))
		current_track = path

func stop_music():
	bg_music_player.stop()

func play_music():
	if not bg_music_player.playing:
		bg_music_player.play()
