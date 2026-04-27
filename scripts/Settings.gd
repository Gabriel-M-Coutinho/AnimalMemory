extends Control

@onready var settings_panel = $SettingsPanel
@onready var volume_slider = $SettingsPanel/Panel/VBoxContainer/VolumeSlider

func _ready():
	settings_panel.visible = false
	volume_slider.value = AppSettings.master_volume_linear

func _on_settings_pressed():
	settings_panel.visible = true

func _on_close_settings_pressed():
	settings_panel.visible = false

func _on_volume_slider_value_changed(value):
	AppSettings.set_master_volume_linear(value)
