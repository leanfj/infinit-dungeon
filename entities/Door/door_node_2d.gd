extends Node2D

signal door_opened
signal door_entered

@export var required_keys: int = 1
@export var next_spawn_path: NodePath
@export var teleport_player: bool = true
@export var activate_distance: float = 20.0

@onready var _sprite: AnimatedSprite2D = $CharacterBody2D/AnimatedSprite2D
@onready var _collision: CollisionShape2D = $CharacterBody2D/CollisionShape2D
@onready var _area: Area2D = $CharacterBody2D/Area2D
@onready var _area_collision: CollisionShape2D = $CharacterBody2D/Area2D/CollisionShape2D

var _is_open: bool = false

func _ready() -> void:
	_area.body_entered.connect(_on_body_entered)
	if _sprite and _sprite.sprite_frames and _sprite.sprite_frames.has_animation("open"):
		_sprite.sprite_frames.set_animation_loop("open", false)

func _physics_process(_delta: float) -> void:
	if _is_open:
		return
	var player := _get_player()
	if player and player is Node2D:
		if player.global_position.distance_to(global_position) <= activate_distance:
			_try_open_with_player(player, true)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	_try_open_with_player(body)
	if _is_open:
		if teleport_player:
			_teleport_player(body)
		door_entered.emit()


func _open() -> void:
	if _is_open:
		return
	_is_open = true
	if _sprite:
		_sprite.play("open")
	if _collision:
		_collision.disabled = true
	if _area_collision:
		_area_collision.disabled = false
	door_opened.emit()


func _teleport_player(player: Node) -> void:
	if not (player is Node2D):
		return
	var target := _get_next_spawn_global()
	if target != null:
		player.global_position = target


func _get_next_spawn_global() -> Vector2:
	if next_spawn_path != NodePath("") and has_node(next_spawn_path):
		var node := get_node_or_null(next_spawn_path)
		if node and node is Node2D:
			return node.global_position
	# Fallback: search by node name in tree.ssd
	if get_tree() and get_tree().current_scene:
		var found := get_tree().current_scene.find_child("Room2Spawn", true, false)
		if found and found is Node2D:
			return found.global_position
	return global_position


func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") if get_tree() else null


func _try_open_with_player(player: Node, teleport_on_open: bool = false) -> void:
	if _is_open:
		return
	if player.has_method("use_key") and player.use_key(required_keys):
		_open()
		if teleport_player and teleport_on_open:
			_teleport_player(player)
			door_entered.emit()
