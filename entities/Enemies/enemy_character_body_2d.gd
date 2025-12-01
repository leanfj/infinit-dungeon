extends CharacterBody2D

# Enemy that chases the player inside a range and dies on hit.
var _move_speed: float = 50.0
var _chase_range: float = 80.0
var _player: Node2D = null
@onready var _hit_box: HitBoxArea2D = get_node_or_null("HitBoxArea2D")
var _knockback_timer: float = 0.0
var _knockback_direction: Vector2 = Vector2.ZERO
var _is_hurt: bool = false

@export_category("Variables")
@export var move_speed: float = 50.0
@export var chase_range: float = 80.0
@export var health: int = 3
@export var knockback_strength: float = 50.0


@export_category("Objects")
@export var _animation_sprite: AnimatedSprite2D
@export var _player_path: NodePath

func _ready() -> void:
	if _animation_sprite == null:
		_animation_sprite = get_node_or_null("AnimatedSprite2D")
	# Guarantee hit animation does not loop forever; needed for animation_finished handling.
	if _animation_sprite and _animation_sprite.sprite_frames and _animation_sprite.sprite_frames.has_animation("hit"):
		_animation_sprite.sprite_frames.set_animation_loop("hit", false)

	if _hit_box:
		_hit_box.hit_detected.connect(_on_hit_box_hit_detected)
	_move_speed = move_speed
	_chase_range = chase_range
	_set_player_reference()

func _physics_process(_delta: float) -> void:
	if _knockback_timer > 0.0:
		_knockback_timer -= _delta
		velocity = _knockback_direction * knockback_strength
		if _animation_sprite and _animation_sprite.animation != "hit":
			_animation_sprite.play("hit")
		move_and_slide()
		return

	if not is_instance_valid(_player):
		_set_player_reference()

	if _player:
		var distance_to_player: float = global_position.distance_to(_player.global_position)
		if distance_to_player <= _chase_range:
			var direction: Vector2 = (_player.global_position - global_position).normalized()
			velocity = direction * _move_speed
			flip_towards_player()
			_animate()
		else:
			velocity = Vector2.ZERO
			_animate()
	else:
		velocity = Vector2.ZERO
		_animate()

	move_and_slide()

func take_damage(amount: int, origin: Vector2 = Vector2.ZERO) -> void:
	health -= amount
	_is_hurt = true
	var knockback_vector: Vector2 = (global_position - origin).normalized()
	if knockback_vector == Vector2.ZERO:
		knockback_vector = Vector2.UP
	_knockback_direction = knockback_vector
	_knockback_timer = 0.15

	if health > 0 and _animation_sprite:
		await _play_hit_animation(0.5)
		_is_hurt = false
		_animate()
	else:
		if _animation_sprite:
			await _play_hit_animation(0.5)
		await get_tree().create_timer(0.05).timeout
		queue_free()

func enemy_attack() -> void:
	# Placeholder for enemy attack logic
	pass

func _animate() -> void:
	if _is_hurt:
		return

	if velocity.length() > 0:
		if _animation_sprite and _animation_sprite.animation != "run":
			_animation_sprite.play("run")
	else:
		if _animation_sprite and _animation_sprite.animation != "idle":
			_animation_sprite.play("idle")

func _set_player_reference() -> void:
	# Order: explicit path -> first node in group \"player\" -> sibling named PlayerCharacterBody2D.
	if _player_path != NodePath(""):
		_player = get_node_or_null(_player_path) as Node2D
	if _player == null:
		var player_group := get_tree().get_first_node_in_group("player")
		if player_group and player_group is Node2D:
			_player = player_group
	if _player == null and get_parent():
		_player = get_parent().get_node_or_null("PlayerCharacterBody2D") as Node2D

func flip_towards_player() -> void:
	if is_instance_valid(_player) and _animation_sprite:
		if _player.global_position.x >= global_position.x:
			_animation_sprite.flip_h = false
		else:
			_animation_sprite.flip_h = true


func _on_hit_box_hit_detected(amount: int, origin: Vector2) -> void:
	take_damage(amount, origin)


func _play_hit_animation(wait_time: float) -> void:
	if _animation_sprite:
		_animation_sprite.play("hit")
	await get_tree().create_timer(wait_time).timeout
