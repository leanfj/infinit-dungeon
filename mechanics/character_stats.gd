extends Resource
class_name CharacterStats

signal leveled_up(new_level: int)

@export var level: int = 1
@export var experience: int = 0
@export var experience_to_next: int = 5
@export var max_health: int = 6
@export var current_health: int = 6
@export var move_speed: float = 100.0
@export var damage: int = 1

func apply_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)

func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)

func gain_experience(amount: int) -> void:
	experience += amount
	while experience >= experience_to_next:
		experience -= experience_to_next
		_level_up()

func _level_up() -> void:
	level += 1
	# Simple scaling: increase thresholds and stats modestly.
	experience_to_next = int(experience_to_next * 1.2) + 1
	max_health += 2
	current_health = max_health
	damage += 1
	move_speed += 5.0
	leveled_up.emit(level)
