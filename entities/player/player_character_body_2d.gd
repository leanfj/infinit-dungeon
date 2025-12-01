extends CharacterBody2D
class_name PlayerCharacter

var _can_attack:bool = true
var _attack_animation_name: String = ""
var _knockback_timer: float = 0.0
var _knockback_direction: Vector2 = Vector2.ZERO
var _smoke_spawn_timer: float = 0.0
var _smoke_spawn_interval: float = 0.1  # Spawn smoke every 0.1 seconds when moving

signal health_changed(current: int, max: int)
signal died
signal keys_changed(count: int)

@export_category("Variables")
@export var _move_speed: float = 128.0
@export var _primary_attack_name: String = ""
@export var _secondary_attack_name: String = ""
@export var _secondary_attack_cooldown: float = 0.5
@export var _max_health: int = 6 # health in half-hearts (2 points per heart)
@export var _player_health: int = 6
@export var _knockback_strength: float = 150.0
@export var key_count: int = 0
const CharacterStats = preload("res://mechanics/character_stats.gd")

@export var stats: Resource

@export_category("Objetcs")
@export var _animation_sprite: AnimatedSprite2D
@export var _animation_weapon: AnimationPlayer
@export var _weapon_node: Node2D
@export var _fire_ball_marker: Marker2D
@onready var _hit_box: HitBoxArea2D = $HitBoxArea2D
@onready var _level_label: Label = get_node_or_null("LevelLabel")

func _ready() -> void:
	if stats == null:
		stats = CharacterStats.new()
	if stats is CharacterStats:
		var cs := stats as CharacterStats
		# push exported defaults into stats
		cs.max_health = _max_health
		cs.current_health = _player_health
		cs.move_speed = _move_speed
		# pull back to node
		_move_speed = cs.move_speed
		_max_health = cs.max_health
		_player_health = cs.current_health
		cs.leveled_up.connect(_on_stats_leveled_up)
	_player_health = clamp(_player_health, 0, _max_health)
	if _animation_weapon:
		_animation_weapon.animation_finished.connect(_on_animation_player_animation_finished)
	if is_instance_valid(_hit_box):
		_hit_box.hit_detected.connect(_on_hit_box_hit_detected)
	_emit_health()
	_emit_keys()

func heal(amount: int, max_cap: int = -1) -> void:
	var cap: int = _max_health
	if stats is CharacterStats:
		cap = (stats as CharacterStats).max_health
	if max_cap >= 0:
		cap = min(max_cap, cap)
	_player_health = clamp(_player_health + amount, 0, cap)
	if stats is CharacterStats:
		(stats as CharacterStats).current_health = _player_health
	_emit_health()


func gain_experience(amount: int) -> void:
	if not (stats is CharacterStats):
		return
	var cs := stats as CharacterStats
	cs.gain_experience(amount)
	_sync_from_stats()


func _sync_from_stats() -> void:
	if not (stats is CharacterStats):
		return
	var cs := stats as CharacterStats
	_move_speed = cs.move_speed
	_max_health = cs.max_health
	_player_health = clamp(cs.current_health, 0, _max_health)
	_emit_health()
	_update_level_label()


func _on_stats_leveled_up(_new_level: int) -> void:
	if stats is CharacterStats:
		var cs := stats as CharacterStats
		cs.current_health = cs.max_health
	_sync_from_stats()
	_update_level_label()


func _update_level_label() -> void:
	if _level_label and stats is CharacterStats:
		var cs := stats as CharacterStats
		_level_label.text = "Lv %d" % cs.level

func _physics_process(_delta: float) -> void:
	if _knockback_timer > 0.0:
		_knockback_timer -= _delta
		velocity = _knockback_direction * _knockback_strength
		move_and_slide()
		return

	_move()
	_attack()
	_animate()
	_spawn_smoke(_delta)

func _attack() -> void:
	if Input.is_action_pressed("primary_attack") and _can_attack:
		_start_attack(_primary_attack_name)
		
	elif Input.is_action_just_pressed("secondary_attack") and _can_attack:
		_start_attack(_secondary_attack_name)

func _start_attack(anim_name: String) -> void:
	_can_attack = false
	_attack_animation_name = anim_name
	if _animation_weapon and _animation_weapon.current_animation != anim_name:
		_animation_weapon.play(anim_name)
		if is_instance_valid(_fire_ball_marker) and anim_name == _primary_attack_name:
			var fire_ball_scene: PackedScene = preload("res://entities/player/Mage/FireBall/fire_ball_node_2d.tscn")
			var fire_ball_instance: Area2D = fire_ball_scene.instantiate() as Area2D
			get_parent().add_child(fire_ball_instance)
			fire_ball_instance.global_position = _fire_ball_marker.global_position
			var mouse_direction: Vector2 = (get_global_mouse_position() - global_position).normalized()
			fire_ball_instance.set_direction(mouse_direction)
	
func _move() -> void:
	var _direction: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	)
	velocity = _direction * _move_speed

	var mouse_direction: Vector2 = (get_global_mouse_position() - global_position).normalized()

	if mouse_direction.x >= 0:
		_animation_sprite.flip_h = false
	else:
		_animation_sprite.flip_h = true

	
	_weapon_node.rotation = mouse_direction.angle()

	if _weapon_node.rotation > PI / 2 or _weapon_node.rotation < -PI / 2:
		_weapon_node.scale.y = -1
	else:
		_weapon_node.scale.y = 1
	

	move_and_slide()
	
func _animate() -> void:
	if velocity.x > 0:
		_animation_sprite.flip_h = false
	
	if velocity.x < 0:
		_animation_sprite.flip_h = true
		
	if _can_attack == false:
		if _animation_weapon and _animation_weapon.current_animation != _attack_animation_name:
			_animation_weapon.play(_attack_animation_name)
		return

	if velocity:
		_animation_sprite.play("run")
		return
		
	_animation_sprite.play("idle")



func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	if _anim_name == _primary_attack_name or _anim_name == _secondary_attack_name:
		_can_attack = true
		# set_physics_process(true)
		if _anim_name == _primary_attack_name and Input.is_action_pressed("primary_attack"):
			_start_attack(_primary_attack_name)


# Suporte a conexão já criada na cena (AnimationPlayer.signal)
func _on_staff_animation_player_animation_finished(_anim_name: StringName) -> void:
	_on_animation_player_animation_finished(_anim_name)


func _on_hit_box_hit_detected(amount: int, origin: Vector2) -> void:
	_player_health -= amount
	if stats is CharacterStats:
		(stats as CharacterStats).apply_damage(amount)
	_player_health = clamp(_player_health, 0, _max_health)
	_emit_health()
	_animation_sprite.play("hurt")
	_can_attack = false
	if _animation_weapon:
		_animation_weapon.stop()

	var knockback_vector: Vector2 = (global_position - origin).normalized()
	if knockback_vector == Vector2.ZERO:
		knockback_vector = Vector2.RIGHT
	_knockback_direction = knockback_vector
	_knockback_timer = 0.15
	velocity = _knockback_direction * _knockback_strength

	if _player_health <= 0:
		died.emit()
		await get_tree().create_timer(0.2).timeout
		queue_free()
		return

	await get_tree().create_timer(0.2).timeout
	_can_attack = true
	_attack_animation_name = ""
	_animate()


func _emit_health() -> void:
	health_changed.emit(_player_health, _max_health)


func add_key(amount: int = 1) -> void:
	key_count = max(0, key_count + amount)
	_emit_keys()


func use_key(amount: int = 1) -> bool:
	if key_count < amount:
		return false
	key_count -= amount
	_emit_keys()
	return true


func _emit_keys() -> void:
	keys_changed.emit(key_count)


func _spawn_smoke(_delta: float) -> void:
	# Só spawn fumaça se estiver se movendo
	if velocity.length() < 10.0:
		_smoke_spawn_timer = 0.0
		return
	
	_smoke_spawn_timer += _delta
	
	if _smoke_spawn_timer >= _smoke_spawn_interval:
		_smoke_spawn_timer = 0.0
		
		var smoke_scene: PackedScene = preload("res://mechanics/RunSmoke/run_smoke_node_2d.tscn")
		var smoke_instance: Node2D = smoke_scene.instantiate() as Node2D
		
		if get_parent():
			get_parent().add_child(smoke_instance)
			# Posiciona a fumaça atrás do player
			smoke_instance.global_position = global_position
			smoke_instance.position.y += 11.0
			#Realizar o flip da fumaça baseado na direção do movimento
			if velocity.x < 0:
				smoke_instance.scale.x = -1.0
			else:
				smoke_instance.scale.x = 1.0
			# Z-index menor para ficar atrás
			smoke_instance.z_index = z_index - 1
