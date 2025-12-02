extends CanvasLayer

@export var full_heart: Texture2D
@export var half_heart: Texture2D
@export var empty_heart: Texture2D
@export var heart_spacing: int = 4
@export var heart_size: Vector2 = Vector2(5, 5)
@export var key_icon: Texture2D
@export var player_portrait: Texture2D

@onready var _root: HBoxContainer = HBoxContainer.new()
@onready var _portrait_panel: VBoxContainer = VBoxContainer.new()
@onready var _stats_container: VBoxContainer = VBoxContainer.new()
@onready var _level_label: Label = Label.new()
@onready var _exp_label: Label = Label.new()
@onready var _damage_label: Label = Label.new()
@onready var _speed_label: Label = Label.new()
@onready var _portrait_rect: TextureRect = TextureRect.new()
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
	_update_stats()


func _connect_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as PlayerCharacter
	if _player:
		_player.health_changed.connect(_on_player_health_changed)
		_player.keys_changed.connect(_on_keys_changed)
		_update_from_player(_player._player_health, _player._max_health)
		_keys = _player.key_count
		# Connect to stats signal for updates
		if _player.stats and _player.stats is CharacterStats:
			var cs := _player.stats as CharacterStats
			cs.leveled_up.connect(_on_player_leveled_up)
			cs.experience_gained.connect(_on_player_exp_gained)


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
	_root.alignment = BoxContainer.ALIGNMENT_CENTER
	_root.add_theme_constant_override("separation", 8)
	_root.anchor_left = 0
	_root.anchor_top = 0
	_root.anchor_right = 0
	_root.anchor_bottom = 0
	_root.position = Vector2(8, 8)
	add_child(_root)
	
	# Add portrait panel first
	_setup_portrait_panel()
	_root.add_child(_portrait_panel)

	# Create a VBoxContainer for hearts and keys to align with portrait
	var right_panel := VBoxContainer.new()
	right_panel.alignment = BoxContainer.ALIGNMENT_BEGIN
	right_panel.add_theme_constant_override("separation", 4)
	
	_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	_container.add_theme_constant_override("separation", heart_spacing)
	right_panel.add_child(_container)
	
	_setup_keys_ui()
	right_panel.add_child(_key_container)
	
	_root.add_child(right_panel)


func _setup_portrait_panel() -> void:
	_portrait_panel.alignment = BoxContainer.ALIGNMENT_BEGIN
	_portrait_panel.add_theme_constant_override("separation", 2)
	
	# Portrait image
	_portrait_rect.texture = player_portrait
	_portrait_rect.ignore_texture_size = true
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_rect.custom_minimum_size = Vector2(10, 10)
	_portrait_panel.add_child(_portrait_rect)
	
	# Stats container below portrait
	_stats_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	_stats_container.add_theme_constant_override("separation", 1)
	
	# Level label
	_level_label.text = "Lv 1"
	_level_label.add_theme_font_size_override("font_size", 3)
	_stats_container.add_child(_level_label)
	
	# Experience label
	_exp_label.text = "XP: 0/5"
	_exp_label.add_theme_font_size_override("font_size", 3)
	_stats_container.add_child(_exp_label)
	
	# Damage label
	_damage_label.text = "ATK: 1"
	_damage_label.add_theme_font_size_override("font_size", 3)
	_stats_container.add_child(_damage_label)
	
	# Speed label
	_speed_label.text = "SPD: 100"
	_speed_label.add_theme_font_size_override("font_size", 3)
	_stats_container.add_child(_speed_label)
	
	_portrait_panel.add_child(_stats_container)


func _setup_keys_ui() -> void:
	var key_icon_rect := TextureRect.new()
	key_icon_rect.texture = key_icon
	key_icon_rect.ignore_texture_size = true
	key_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	key_icon_rect.custom_minimum_size = Vector2(12, 12)
	_key_container.add_child(key_icon_rect)

	_key_label.text = str(_keys)
	_key_label.add_theme_font_size_override("font_size", 5)
	_key_container.add_child(_key_label)

	_key_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	_key_container.add_theme_constant_override("separation", 0)


func _on_keys_changed(count: int) -> void:
	_keys = count
	_update_keys()


func _update_keys() -> void:
	_key_label.text = "x%s" % _keys
	if _key_container.get_child_count() > 0:
		var icon := _key_container.get_child(0) as TextureRect
		if icon:
			icon.texture = key_icon


func _update_stats() -> void:
	if not _player or not _player.stats:
		return
	
	if _player.stats is CharacterStats:
		var cs := _player.stats as CharacterStats
		_level_label.text = "Lv %d" % cs.level
		_exp_label.text = "XP: %d/%d" % [cs.experience, cs.experience_to_next]
		_damage_label.text = "ATK: %d" % cs.damage
		_speed_label.text = "SPD: %d" % int(cs.move_speed)


func _on_player_leveled_up(_new_level: int) -> void:
	_update_stats()


func _on_player_exp_gained(_current_exp: int, _exp_to_next: int) -> void:
	_update_stats()
