extends Area2D

@export var heal_amount: int = 2
@export var max_health_cap: int = -1 # -1 uses player's max

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	var heal_to := heal_amount
	if body.has_method("heal"):
		body.heal(heal_to, max_health_cap)
	queue_free()
