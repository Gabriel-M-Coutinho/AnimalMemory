extends Node

var loading_screen_scene = preload("res://scenes/Loading.tscn")
var loading_screen_instance: Control
var target_scene_path: String = ""
var is_loading: bool = false
var min_display_time: float = 0.8
var start_time: float = 0.0

func _ready():
	process_mode = PROCESS_MODE_ALWAYS

func goto_scene(path: String):
	target_scene_path = path
	is_loading = true
	start_time = Time.get_ticks_msec() / 1000.0
	
	# Add loading screen
	loading_screen_instance = loading_screen_scene.instantiate()
	get_tree().root.add_child(loading_screen_instance)
	
	# Start background load
	ResourceLoader.load_threaded_request(path)

func _process(_delta):
	if is_loading:
		var progress = []
		var status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
		
		if loading_screen_instance:
			var progress_bar = loading_screen_instance.find_child("ProgressBar", true)
			if progress_bar:
				# Use max of actual progress and a slight interpolation
				var target_val = progress[0] * 100
				progress_bar.value = move_toward(progress_bar.value, target_val, 2.0)
		
		var current_time = Time.get_ticks_msec() / 1000.0
		var elapsed = current_time - start_time
		
		if status == ResourceLoader.THREAD_LOAD_LOADED and elapsed >= min_display_time:
			var new_scene = ResourceLoader.load_threaded_get(target_scene_path)
			get_tree().change_scene_to_packed(new_scene)
			
			loading_screen_instance.queue_free()
			loading_screen_instance = null
			is_loading = false
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			is_loading = false
			loading_screen_instance.queue_free()
