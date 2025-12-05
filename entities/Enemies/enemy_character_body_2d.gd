extends CharacterBody2D
class_name EnemyCharacterBody2D

const EnemyStatsInstance = preload("res://mechanics/enemy_stats.gd")

# Enemy that chases the player inside a range and dies on hit.
@onready var _hit_box: HitBoxArea2D = get_node_or_null("HitBoxArea2D")
@onready var hurt_audio_stream_player_2d: AudioStreamPlayer2D = $HurtAudioStreamPlayer2D
@onready var death_audio_stream_player_2d: AudioStreamPlayer2D = $DeathAudioStreamPlayer2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var _contact_area: Area2D = get_node_or_null("ContactArea2D")

var deathExplosionParticles2D = preload("res://mechanics/death_cpu_particles_2d.tscn")
var _move_speed: float = 50.0
var _chase_range: float = 80.0
var _player: Node2D = null
var _knockback_timer: float = 0.0
var _knockback_direction: Vector2 = Vector2.ZERO
var _is_hurt: bool = false
var _is_dead: bool = false
var _contact_timer: float = 0.0
var _contact_targets: Array[Node2D] = []

@export_category("Variables")
@export var move_speed: float = 50.0
@export var chase_range: float = 80.0
@export var health: int = 3
@export var knockback_strength: float = 50.0
@export var stats: Resource
@export var exp_reward: int = 3
@export var contact_damage: int = 1
@export var contact_cooldown: float = 0.6
@export var min_contact_distance: float = 8.0
@export var contact_push: float = 12.0


@export_category("Objects")
@export var _animation_sprite: AnimatedSprite2D
@export var _player_path: NodePath


func _ready() -> void:
	if _animation_sprite == null:
		_animation_sprite = get_node_or_null("AnimatedSprite2D")
	# Guarantee hit animation does not loop forever; needed for animation_finished handling.
	if _animation_sprite and _animation_sprite.sprite_frames and _animation_sprite.sprite_frames.has_animation("hit"):
		_animation_sprite.sprite_frames.set_animation_loop("hit", false)

	if stats is EnemyStats:
		_move_speed = (stats as EnemyStats).move_speed
		health = randi_range((stats as EnemyStats).min_health, (stats as EnemyStats).max_health)
		contact_damage = (stats as EnemyStats).damage
		exp_reward = (stats as EnemyStats).experience

	if _hit_box:
		_hit_box.hit_detected.connect(_on_hit_box_hit_detected)
	if _contact_area:
		_contact_area.body_entered.connect(_on_contact_body_entered)
		_contact_area.body_exited.connect(_on_contact_body_exited)
	# _move_speed = move_speed
	_chase_range = chase_range
	_set_player_reference()

func _physics_process(_delta: float) -> void:
	if _is_dead:
		return
	_contact_timer = max(0.0, _contact_timer - _delta)
	if _knockback_timer > 0.0:
		_knockback_timer -= _delta
		velocity = _knockback_direction * knockback_strength
		if _animation_sprite and _animation_sprite.animation != "hit":
			_animation_sprite.play("hit")
		move_and_slide()
		return

	if not is_instance_valid(_player):
		_set_player_reference()

	if _player and not _is_dead:
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
	_handle_contact_damage()

func take_damage(amount: int, origin: Vector2 = Vector2.ZERO) -> void:
	if _is_dead:
		return
	if stats and stats.has_method("apply_damage"):
		stats.apply_damage(amount)
	health -= amount
	_is_hurt = true
	var knockback_vector: Vector2 = (global_position - origin).normalized()
	if knockback_vector == Vector2.ZERO:
		knockback_vector = Vector2.UP
	_knockback_direction = knockback_vector
	_knockback_timer = 0.15

	if health > 0 and _animation_sprite:
		if hurt_audio_stream_player_2d:
			hurt_audio_stream_player_2d.play()
		_particles_death_effect()
		await _play_hit_animation(0.5)
		_is_hurt = false
		_animate()
	else:
		if _is_dead:
			return
		_is_dead = true

		collision_shape_2d.set_deferred("disabled", true)
	
		if _animation_sprite:
			if hurt_audio_stream_player_2d:
				hurt_audio_stream_player_2d.play()
			await _play_hit_animation(0.5)
		_reward_player()
		
		if death_audio_stream_player_2d:
			death_audio_stream_player_2d.play()
		velocity = Vector2.ZERO
		_animate()
		await get_tree().create_timer(0.6).timeout

		queue_free()

func enemy_attack() -> void:
	# Placeholder for enemy attack logic
	pass

func _animate() -> void:
	if velocity.length() > 0 and not _is_hurt and not _is_dead:
		if _animation_sprite and _animation_sprite.animation != "run":
			_animation_sprite.play("run")
	elif velocity.length() == 0 and not _is_hurt and not _is_dead:
		if _animation_sprite and _animation_sprite.animation != "idle":
			_animation_sprite.play("idle")
	else:
		if _is_dead:
			if _animation_sprite and _animation_sprite.animation != "dead":
				_animation_sprite.play("dead")

func _set_player_reference() -> void:
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


func _reward_player() -> void:
	var player := _player if is_instance_valid(_player) else get_tree().get_first_node_in_group("player")
	if player and player.has_method("gain_experience"):
		player.gain_experience(exp_reward)


func _handle_contact_damage() -> void:
	if _is_dead:
		return
	if _is_hurt:
		return
	if _contact_timer > 0.0:
		return
	if not _contact_area or not _contact_area.monitoring:
		return
	var target := _get_contact_target()
	if target == null:
		return

	_apply_contact_damage(target)
	_contact_timer = contact_cooldown
	var away := (global_position - target.global_position).normalized()
	if away == Vector2.ZERO:
		away = Vector2.RIGHT
	global_position += away * contact_push


func _apply_contact_damage(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	var hitbox: Node = target.get_node_or_null("HitBoxArea2D")
	if hitbox and hitbox.has_method("take_damage"):
		hitbox.take_damage(contact_damage, global_position)


func _on_contact_body_entered(body: Node) -> void:
	if body is Node2D and body.is_in_group("player"):
		_contact_targets.append(body)


func _on_contact_body_exited(body: Node) -> void:
	_contact_targets.erase(body)


func _get_contact_target() -> Node2D:
	for target in _contact_targets:
		if is_instance_valid(target):
			return target
	if is_instance_valid(_player) and global_position.distance_to(_player.global_position) <= min_contact_distance:
		return _player
	return null


func _play_hit_animation(wait_time: float) -> void:
	if _animation_sprite:
		_animation_sprite.play("hit")
		
	await get_tree().create_timer(wait_time).timeout
	
func _play_death_sound() -> void:
	if death_audio_stream_player_2d:
		death_audio_stream_player_2d.play()


func _particles_death_effect() -> void:
	var death_particles = deathExplosionParticles2D.instantiate()
	death_particles.z_index = z_index + 1
	death_particles.global_position = global_position
	get_tree().current_scene.add_child(death_particles)
