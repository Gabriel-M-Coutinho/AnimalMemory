extends Control

signal card_clicked(card_node)

@export var card_id: String = ""
@export var is_flipped: bool = false
@export var is_matched: bool = false

@onready var card_sprite: AnimatedSprite2D = $Animations

# Atalho para o Autoload — funciona após registrar em Projeto → Autoload
var _db: Node:
	get: return get_node_or_null("/root/CardDatabase")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	resized.connect(_on_resized)
	gui_input.connect(_on_gui_input)
	_on_resized()

func _on_resized() -> void:
	if card_sprite:
		card_sprite.position = size / 2.0
	update_visuals()

## Configura a carta com um ID que existe em cards.json.
func setup(id: String) -> void:
	card_id = id
	_apply_sprite()
	update_visuals()

func _apply_sprite() -> void:
	if card_id == "" or _db == null:
		if _db == null:
			push_error("card.gd: CardDatabase não encontrado em /root/. Registre o Autoload.")
		return

	var frames: SpriteFrames = _db.get_sprite_frames(card_id)
	if frames == null:
		return

	card_sprite.sprite_frames = frames

var _flip_scale: float = 1.0

func flip(show_front: bool) -> void:
	if is_matched or is_flipped == show_front:
		return
	
	is_flipped = show_front
	
	var tween = create_tween()
	# Animamos apenas o multiplicador de flip, sem mexer no scale real diretamente
	tween.tween_property(self, "_flip_scale", 0.0, 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(update_visuals)
	tween.tween_property(self, "_flip_scale", 1.0, 0.1).set_trans(Tween.TRANS_SINE)

func update_visuals() -> void:
	if not card_sprite or not card_sprite.sprite_frames:
		return
		
	if is_flipped:
		if is_matched and card_sprite.sprite_frames.has_animation("movement"):
			card_sprite.play("movement")
		elif card_sprite.sprite_frames.has_animation("idle"):
			card_sprite.play("idle")
	else:
		card_sprite.play("cardback")

	# Cálculo de escala seguro
	var anim_w = 345.0
	var anim_h = 522.0
	
	var tex = card_sprite.sprite_frames.get_frame_texture(card_sprite.animation, 0)
	if tex:
		var tw = tex.get_width()
		var th = tex.get_height()
		if tw > 0 and th > 0:
			anim_w = float(tw)
			anim_h = float(th)

	if size.x > 0 and size.y > 0:
		var scale_x = size.x / anim_w
		var scale_y = size.y / anim_h
		var scale_factor = min(scale_x, scale_y)
		
		# Aplicamos o multiplicador de flip apenas no eixo X
		card_sprite.scale = Vector2(scale_factor * _flip_scale, scale_factor)

func _process(_delta: float) -> void:
	# Mantemos o visual atualizado se o flip estiver acontecendo
	if _flip_scale < 1.0:
		update_visuals()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not is_flipped and not is_matched:
				card_clicked.emit(self)
