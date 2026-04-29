extends Node

const DEFAULT_PLAYER_NAME := "Jogador(a) 1"
const RANKING_PATH := "user://ranking.json"
const MAX_ENTRIES_PER_DIFFICULTY := 10

var player_name: String = DEFAULT_PLAYER_NAME
var _ranking_cache: Dictionary = {} # difficulty -> Array[Dictionary]

func set_player_name(name: String) -> void:
	var trimmed := name.strip_edges()
	player_name = trimmed if trimmed.length() > 0 else DEFAULT_PLAYER_NAME

func get_player_name() -> String:
	return player_name

func _ensure_ranking_loaded() -> void:
	if not _ranking_cache.is_empty():
		return
	_ranking_cache = _load_ranking_from_disk()
	
	# Ensure default user exists
	var users: Array = _ranking_cache.get("__users__", [])
	if not DEFAULT_PLAYER_NAME in users:
		users.append(DEFAULT_PLAYER_NAME)
		_ranking_cache["__users__"] = users
		_save_ranking_to_disk(_ranking_cache)

func get_ranking(difficulty: String) -> Array:
	_ensure_ranking_loaded()
	if not _ranking_cache.has(difficulty):
		return []
	return _ranking_cache[difficulty]

func get_all_users() -> Array:
	_ensure_ranking_loaded()
	var names_set = {}
	
	if _ranking_cache.has("__users__"):
		for u in _ranking_cache["__users__"]:
			names_set[u] = true
			
	var arr = names_set.keys()
	arr.sort()
	return arr

func register_user(name: String) -> void:
	_ensure_ranking_loaded()
	var arr: Array = _ranking_cache.get("__users__", [])
	if not name in arr:
		arr.append(name)
		_ranking_cache["__users__"] = arr
		_save_ranking_to_disk(_ranking_cache)

func add_win_score(difficulty: String, score: float) -> int:
	_ensure_ranking_loaded()
	var entry := {
		"name": player_name,
		"score": snapped(score, 0.01),
		"timestamp_unix": Time.get_unix_time_from_system(),
	}

	var arr: Array = _ranking_cache.get(difficulty, [])
	arr.append(entry)
	arr.sort_custom(func(a, b): return float(a.get("score", 0.0)) > float(b.get("score", 0.0)))
	if arr.size() > MAX_ENTRIES_PER_DIFFICULTY:
		arr = arr.slice(0, MAX_ENTRIES_PER_DIFFICULTY)
	_ranking_cache[difficulty] = arr

	_save_ranking_to_disk(_ranking_cache)
	return _find_entry_rank(arr, entry)

func _find_entry_rank(arr: Array, entry: Dictionary) -> int:
	for i in range(arr.size()):
		var e: Dictionary = arr[i]
		if e.get("timestamp_unix") == entry.get("timestamp_unix") and e.get("name") == entry.get("name") and e.get("score") == entry.get("score"):
			return i + 1
	return -1

func clear_ranking(difficulty: String) -> void:
	_ensure_ranking_loaded()
	if _ranking_cache.has(difficulty):
		_ranking_cache[difficulty] = []
		_save_ranking_to_disk(_ranking_cache)

func reset_ranking() -> void:
	_ranking_cache = {}
	_save_ranking_to_disk(_ranking_cache)

func _load_ranking_from_disk() -> Dictionary:
	if not FileAccess.file_exists(RANKING_PATH):
		return {}
	var f := FileAccess.open(RANKING_PATH, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

func _save_ranking_to_disk(data: Dictionary) -> void:
	var f := FileAccess.open(RANKING_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))
	f.close()
