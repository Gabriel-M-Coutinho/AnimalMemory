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

func flip(show_front: bool) -> void:
	if is_matched:
		return
	is_flipped = show_front
	update_visuals()

func update_visuals() -> void:
	if not card_sprite or not card_sprite.sprite_frames:
		return

	var anim_w = 64.0
	var anim_h = 64.0

	if not is_flipped:
		if card_sprite.sprite_frames.has_animation("cardback"):
			card_sprite.play("cardback")
			var tex = card_sprite.sprite_frames.get_frame_texture("cardback", 0)
			if tex:
				anim_w = float(tex.get_width())
				anim_h = float(tex.get_height())
	else:
		if is_matched and card_sprite.sprite_frames.has_animation("movement"):
			card_sprite.play("movement")
		elif card_sprite.sprite_frames.has_animation("idle"):
			card_sprite.play("idle")
			
		var card_data = _db.get_card(card_id)
		if card_data:
			anim_w = float(card_data.get("frame_width", 64))
			anim_h = float(card_data.get("frame_height", 64))

	if anim_w > 0 and anim_h > 0 and size.x > 0 and size.y > 0:
		var scale_x = size.x / anim_w
		var scale_y = size.y / anim_h
		
		# Usamos o mesmo fator de escala proporcional para frente e verso.
		# Isso garante que o verso tenha o mesmo tamanho exato do animal.
		var scale_factor = min(scale_x, scale_y)
		card_sprite.scale = Vector2(scale_factor, scale_factor)

	if is_matched:
		pass # modulate.a = 0.5 removido para não escurecer a carta!

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not is_flipped and not is_matched:
				card_clicked.emit(self)
