extends Node

const SETTINGS_PATH := "user://settings.json"

var master_volume_linear: float = 0.5

func _ready() -> void:
	_load()
	_apply_audio()

func set_master_volume_linear(v: float) -> void:
	master_volume_linear = clampf(v, 0.0, 1.0)
	_apply_audio()
	_save()

func _apply_audio() -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(master_volume_linear))

func _load() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var d: Dictionary = parsed

	if d.has("master_volume_linear"):
		master_volume_linear = clampf(float(d.get("master_volume_linear", master_volume_linear)), 0.0, 1.0)

func _save() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f == null:
		return
	var data := {
		"master_volume_linear": master_volume_linear,
	}
	f.store_string(JSON.stringify(data))
	f.close()
