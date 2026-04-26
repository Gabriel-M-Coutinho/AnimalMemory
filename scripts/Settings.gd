extends Control

@onready var settings_panel = $SettingsPanel
@onready var volume_slider = $SettingsPanel/Panel/VBoxContainer/VolumeSlider

func _ready():
	settings_panel.visible = false
	# Initialize slider with median volume (0.5)
	var bus_index = AudioServer.get_bus_index("Master")
	volume_slider.value = 0.5
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(0.5))

func _on_settings_pressed():
	settings_panel.visible = true

func _on_close_settings_pressed():
	settings_panel.visible = false

func _on_volume_slider_value_changed(value):
	var bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
