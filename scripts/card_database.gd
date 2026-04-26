extends Node

## CardDatabase
## Autoload que carrega cards.json e monta SpriteFrames dinamicamente.
## Registre em: Projeto → Configurações do Projeto → Autoload
## Caminho: res://scripts/card_database.gd  |  Nome: CardDatabase

const DATA_PATH := "res://data/cards.json"

var _cards: Dictionary = {}  # { "id" -> dados da carta }

func _ready() -> void:
	_load_database()

func _load_database() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if not file:
		push_error("CardDatabase: Não foi possível abrir %s" % DATA_PATH)
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("CardDatabase: Erro ao parsear JSON — %s" % json.get_error_message())
		return

	for card_data in json.data.get("cards", []):
		var id: String = card_data.get("id", "")
		if id != "":
			_cards[id] = card_data

	print("CardDatabase: %d cartas carregadas." % _cards.size())

## Retorna os dados brutos de uma carta pelo ID.
func get_card(id: String) -> Variant:
	return _cards.get(id, null)

## Retorna todos os IDs disponíveis.
func get_all_ids() -> Array:
	return _cards.keys()

## Monta e retorna um SpriteFrames com as animações definidas no JSON.
## Cada animação usa uma linha (row) do spritesheet.
func get_sprite_frames(id: String) -> SpriteFrames:
	var card_data = get_card(id)
	if card_data == null:
		push_warning("CardDatabase: ID '%s' não encontrado." % id)
		return null

	var sprite_path: String = card_data.get("sprite", "")
	var texture: Texture2D = load(sprite_path)
	if texture == null:
		push_warning("CardDatabase: Sprite '%s' não pôde ser carregado." % sprite_path)
		return null

	var frame_w: int = card_data.get("frame_width",  64)
	var frame_h: int = card_data.get("frame_height", 64)
	var animations: Dictionary = card_data.get("animations", {})

	var sprite_frames := SpriteFrames.new()
	# Remove a animação "default" que vem por padrão
	sprite_frames.remove_animation("default")
	
	# Injeta o cardback dinamicamente usando a imagem completa
	var back_tex: Texture2D = load("res://sprites/card_back.png")
	if back_tex:
		sprite_frames.add_animation("cardback")
		sprite_frames.add_frame("cardback", back_tex)
		sprite_frames.set_animation_loop("cardback", false)
	
	var cols: int = max(1, int(float(texture.get_width()) / float(frame_w)))

	for anim_name in animations:
		var anim: Dictionary = animations[anim_name]
		var row:    int   = anim.get("row",    0)
		var frames: int   = anim.get("frames", 1)
		var fps:    float = anim.get("fps",    8.0)
		var loop:   bool  = anim.get("loop",   true)
		
		var start_frame: int = anim.get("start_frame", row * cols)

		sprite_frames.add_animation(anim_name)
		sprite_frames.set_animation_speed(anim_name, fps)
		sprite_frames.set_animation_loop(anim_name, loop)

		for i in range(frames):
			var current_index = start_frame + i
			var current_col = current_index % cols
			var current_row = int(float(current_index) / float(cols))
			
			var atlas := AtlasTexture.new()
			atlas.atlas  = texture
			atlas.region = Rect2(current_col * frame_w, current_row * frame_h, frame_w, frame_h)
			sprite_frames.add_frame(anim_name, atlas)

	return sprite_frames
