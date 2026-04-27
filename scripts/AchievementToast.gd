extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var icon_rect: TextureRect = $Panel/Margin/HBox/Icon
@onready var title_label: Label = $Panel/Margin/HBox/VBox/Title
@onready var desc_label: Label = $Panel/Margin/HBox/VBox/Desc

var _player: AudioStreamPlayer
var _hide_tween: Tween

func _ready() -> void:
	panel.visible = false
	_player = AudioStreamPlayer.new()
	add_child(_player)
	# Reuse an existing short sound to avoid adding new assets.
	_player.stream = load("res://sounds/correct.mp3")
	_player.volume_db = -8.0

func show_achievement(achievement_id: String) -> void:
	var info := _get_info(achievement_id)
	title_label.text = info.get("title", "Conquista desbloqueada!")
	desc_label.text = info.get("desc", "")

	if info.has("icon") and info["icon"] != null:
		icon_rect.texture = info["icon"]
	else:
		icon_rect.texture = load("res://icon.svg")

	if _hide_tween and _hide_tween.is_running():
		_hide_tween.kill()

	panel.visible = true
	panel.modulate.a = 1.0
	_player.play()

	_hide_tween = create_tween()
	_hide_tween.tween_interval(2.2)
	_hide_tween.tween_property(panel, "modulate:a", 0.0, 0.35)
	_hide_tween.tween_callback(func(): panel.visible = false)

func _get_info(id: String) -> Dictionary:
	# General achievements
	if id == "win_1":
		return {"title": "Primeira vitória!", "desc": "Você ganhou uma partida.", "icon": load("res://sprites/achievement_star.jpg")}
	if id == "win_5":
		return {"title": "Campeãozinho!", "desc": "Você ganhou 5 partidas.", "icon": load("res://sprites/achievement_medal.jpg")}
	if id == "win_10":
		return {"title": "Mestre da Memória!", "desc": "Você ganhou 10 partidas.", "icon": load("res://sprites/achievement_trophy.jpg")}
	if id == "win_no_hint_1":
		return {"title": "Sem ajuda!", "desc": "Ganhou uma partida sem usar dica.", "icon": load("res://sprites/achievement_brain.jpg")}
	if id == "win_no_hint_5":
		return {"title": "Pro jogador!", "desc": "Ganhou 5 partidas sem usar dica.", "icon": load("res://sprites/achievement_brain.jpg")}

	# Card achievements: card_<id>_<n>
	if id.begins_with("card_"):
		var parts := id.split("_")
		if parts.size() >= 3:
			var card_id := parts[1]
			var threshold := parts[2]
			var card_data = CardDatabase.get_card(card_id)
			var name := str(card_data.get("name", card_id)) if card_data else card_id
			var tex: Texture2D = load("res://sprites/milestone_bronze.jpg")
			return {"title": "Colecionando!", "desc": "%s encontrado %sx" % [name, threshold], "icon": tex}

	return {"title": "Conquista desbloqueada!", "desc": "", "icon": null}
