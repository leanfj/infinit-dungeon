extends Node2D
class_name RunSmoke

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	if _animated_sprite:
		_animated_sprite.play("default")
		_animated_sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	queue_free()
