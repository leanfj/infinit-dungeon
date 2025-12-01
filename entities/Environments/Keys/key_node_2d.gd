extends Area2D

@export var animation_speed: float = 6.0
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	if _sprite and _sprite.sprite_frames:
		_sprite.play("idle")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("add_key"):
		body.add_key(1)
		queue_free()
