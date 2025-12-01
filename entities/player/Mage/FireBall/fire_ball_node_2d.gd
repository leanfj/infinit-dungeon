extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_box: HurtBoxArea2D = $HurtBoxArea2D
#animations hit and travel

@export var speed: float = 200.0
@export var max_distance: float = 50.0

var _direction: Vector2 = Vector2.ZERO
var _has_hit: bool = false
var _origin_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	hurt_box.hurt_detected.connect(_on_hurt_detected)
	
func _physics_process(_delta: float) -> void:
	position += _direction * speed * _delta
	if _origin_position != Vector2.ZERO and global_position.distance_to(_origin_position) >= max_distance:
		await _play_hit_and_free()

func set_direction(direction: Vector2) -> void:
	_direction = direction.normalized()
	_origin_position = global_position

func _on_body_entered(body: Node2D) -> void:
	if _has_hit:
		return
	if body and body.has_method("take_damage"):
		body.take_damage(1, global_position)
	await _play_hit_and_free()


func _on_area_entered(area: Area2D) -> void:
	if _has_hit:
		return
	if area and area.has_method("take_damage"):
		area.take_damage(1, global_position)
	await _play_hit_and_free()


func _on_hurt_detected() -> void:
	await _play_hit_and_free()


func _play_hit_and_free() -> void:
	if _has_hit:
		return
	_has_hit = true
	animated_sprite_2d.play("hit")
	animated_sprite_2d.rotation = _direction.angle()
	_direction = Vector2.ZERO
	await get_tree().create_timer(0.1).timeout
	queue_free()
