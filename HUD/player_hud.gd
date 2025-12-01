extends CanvasLayer

@export var full_heart: Texture2D
@export var half_heart: Texture2D
@export var empty_heart: Texture2D
@export var heart_spacing: int = 4
@export var heart_size: Vector2 = Vector2(8, 8)
@export var key_icon: Texture2D

@onready var _root: HBoxContainer = HBoxContainer.new()
@onready var _container: HBoxContainer = HBoxContainer.new()
@onready var _key_container: HBoxContainer = HBoxContainer.new()
@onready var _key_label: Label = Label.new()
var _max_hearts: int = 3
var _current_hearts: int = 3
var _player: PlayerCharacter = null
var _keys: int = 0


func _ready() -> void:
	_setup_layout()
	_connect_player()
	_update_hearts()
	_update_keys()


func _connect_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as PlayerCharacter
	if _player:
		_player.health_changed.connect(_on_player_health_changed)
		_player.keys_changed.connect(_on_keys_changed)
		_update_from_player(_player._player_health, _player._max_health)
		_keys = _player.key_count


func _on_player_health_changed(current: int, max: int) -> void:
	_update_from_player(current, max)


func _update_from_player(current: int, max: int) -> void:
	_max_hearts = int(ceil(max / 2.0))
	_current_hearts = current
	_update_hearts()
	_update_keys()


func _update_hearts() -> void:
	_build_hearts(_max_hearts)
	for i in range(_container.get_child_count()):
		var heart := _container.get_child(i) as TextureRect
		if heart == null:
			continue
		var remaining := _current_hearts - (i * 2)
		if remaining >= 2:
			heart.texture = full_heart
		elif remaining == 1:
			heart.texture = half_heart if half_heart else full_heart
		else:
			heart.texture = empty_heart


func _build_hearts(count: int) -> void:
	# Adjust the number of heart icons to match max health.
	while _container.get_child_count() < count:
		var heart := TextureRect.new()
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.ignore_texture_size = true
		heart.custom_minimum_size = heart_size
		_container.add_child(heart)

	while _container.get_child_count() > count:
		var child := _container.get_child(_container.get_child_count() - 1)
		_container.remove_child(child)
		child.queue_free()


func _setup_layout() -> void:
	_root.alignment = BoxContainer.ALIGNMENT_BEGIN
	_root.add_theme_constant_override("separation", 12)
	_root.anchor_left = 0
	_root.anchor_top = 0
	_root.anchor_right = 0
	_root.anchor_bottom = 0
	_root.position = Vector2(8, 8)
	add_child(_root)

	_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	_container.add_theme_constant_override("separation", heart_spacing)
	_root.add_child(_container)
	_setup_keys_ui()
	_root.add_child(_key_container)


func _setup_keys_ui() -> void:
	var key_icon_rect := TextureRect.new()
	key_icon_rect.texture = key_icon
	key_icon_rect.ignore_texture_size = true
	key_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	key_icon_rect.custom_minimum_size = Vector2(12, 12)
	_key_container.add_child(key_icon_rect)

	_key_label.text = str(_keys)
	_key_label.add_theme_font_size_override("font_size", 8)
	_key_container.add_child(_key_label)

	_key_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	_key_container.add_theme_constant_override("separation", 2)


func _on_keys_changed(count: int) -> void:
	_keys = count
	_update_keys()


func _update_keys() -> void:
	_key_label.text = "x%s" % _keys
	if _key_container.get_child_count() > 0:
		var icon := _key_container.get_child(0) as TextureRect
		if icon:
			icon.texture = key_icon
