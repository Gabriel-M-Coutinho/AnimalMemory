extends Node

const PATH := "user://progress.json"

var _data: Dictionary = {} # {"users": { "<name>": { ...profile... } } }

func _get_user_key() -> String:
	# PlayerContext is an autoload.
	if is_instance_valid(PlayerContext):
		var n = PlayerContext.get_player_name()
		if n is String and String(n).strip_edges() != "":
			return String(n).strip_edges()
	return "Jogador"

func _get_profile() -> Dictionary:
	if not _data.has("users") or typeof(_data["users"]) != TYPE_DICTIONARY:
		_data["users"] = {}
	var users: Dictionary = _data["users"]
	var key := _get_user_key()
	if not users.has(key) or typeof(users[key]) != TYPE_DICTIONARY:
		users[key] = {
			"card_counts": {},
			"total_wins": 0,
			"wins_no_hint": 0,
			"total_hints_used": 0,
			"unlocked": {}, # achievement_id -> unix_timestamp
		}
	return users[key]

func _get_unlocked() -> Dictionary:
	var p := _get_profile()
	if not p.has("unlocked") or typeof(p["unlocked"]) != TYPE_DICTIONARY:
		p["unlocked"] = {}
	return p["unlocked"]

func _unlock(achievement_id: String) -> bool:
	var unlocked := _get_unlocked()
	if unlocked.has(achievement_id):
		return false
	unlocked[achievement_id] = Time.get_unix_time_from_system()
	_save()
	# Toast popup (if present)
	if is_instance_valid(AchievementToast):
		AchievementToast.show_achievement(achievement_id)
	return true

func _ready() -> void:
	_load()

func record_win(no_hint: bool) -> void:
	var p := _get_profile()
	p["total_wins"] = int(p.get("total_wins", 0)) + 1
	if no_hint:
		p["wins_no_hint"] = int(p.get("wins_no_hint", 0)) + 1
	_save()
	_check_unlocks_after_win()

func record_hint_used() -> void:
	var p := _get_profile()
	p["total_hints_used"] = int(p.get("total_hints_used", 0)) + 1
	_save()

func record_pair_found(card_id: String) -> void:
	if card_id == "":
		return
	var p := _get_profile()
	if not p.has("card_counts") or typeof(p["card_counts"]) != TYPE_DICTIONARY:
		p["card_counts"] = {}
	var cc: Dictionary = p["card_counts"]
	cc[card_id] = int(cc.get(card_id, 0)) + 1
	_save()
	_check_unlocks_after_card(card_id)

func get_card_count(card_id: String) -> int:
	var p := _get_profile()
	var cc: Dictionary = p.get("card_counts", {})
	return int(cc.get(card_id, 0))

func get_total_wins() -> int:
	return int(_get_profile().get("total_wins", 0))

func get_wins_no_hint() -> int:
	return int(_get_profile().get("wins_no_hint", 0))

func get_total_hints_used() -> int:
	return int(_get_profile().get("total_hints_used", 0))

func is_unlocked(card_id: String) -> bool:
	return get_card_count(card_id) > 0

func get_achievement_hits(card_id: String) -> Array:
	# Simple thresholds for kids: 1, 5, 10, 20
	var c := get_card_count(card_id)
	var hits: Array = []
	for t in [1, 5, 10, 20]:
		if c >= t:
			hits.append(t)
	return hits

func get_unlocked_achievements() -> Dictionary:
	return _get_unlocked()

func _check_unlocks_after_win() -> void:
	var wins := get_total_wins()
	if wins >= 1:
		_unlock("win_1")
	if wins >= 5:
		_unlock("win_5")
	if wins >= 10:
		_unlock("win_10")

	var no_hint := get_wins_no_hint()
	if no_hint >= 1:
		_unlock("win_no_hint_1")
	if no_hint >= 5:
		_unlock("win_no_hint_5")

func _check_unlocks_after_card(card_id: String) -> void:
	var c := get_card_count(card_id)
	if c >= 1:
		_unlock("card_%s_1" % card_id)
	if c >= 5:
		_unlock("card_%s_5" % card_id)
	if c >= 10:
		_unlock("card_%s_10" % card_id)
	if c >= 20:
		_unlock("card_%s_20" % card_id)

func _load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var d: Dictionary = parsed

	# Migration from old flat format -> per-user.
	if d.has("users") and typeof(d["users"]) == TYPE_DICTIONARY:
		_data = d
		return

	_data = {"users": {}}
	var users: Dictionary = _data["users"]
	users["Jogador"] = {
		"total_wins": int(d.get("total_wins", 0)),
		"wins_no_hint": int(d.get("wins_no_hint", 0)),
		"total_hints_used": int(d.get("total_hints_used", 0)),
		"card_counts": d.get("card_counts", {}) if typeof(d.get("card_counts", {})) == TYPE_DICTIONARY else {},
		"unlocked": {},
	}

func _save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(_data))
	f.close()
