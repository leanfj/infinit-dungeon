extends Resource
class_name EnemyStats

@export var experience: int = 0
@export var max_health: int = 6
@export var min_health: int = 1
@export var current_health: int = 6
@export var move_speed: float = 100.0
@export var damage: int = 1

func apply_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)

func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)