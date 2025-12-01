class_name HurtBoxArea2D 
extends Area2D

@export_category("Hurt Box Variables")
@export var damage_amount: int = 1
@export var target_groups: Array[String] = []

signal hurt_detected()


func _ready() -> void:
	area_entered.connect(_on_area_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_area_entered(area: Area2D) -> void:
	if not _is_valid_target(area):
		return
	if area is HitBoxArea2D:
		area.take_damage(damage_amount, global_position)
		emit_signal("hurt_detected")


func _is_valid_target(area: Area2D) -> bool:
	if target_groups.is_empty():
		return true
	var owner_node := area.get_parent()
	if owner_node == null:
		owner_node = area
	for group in target_groups:
		if owner_node.is_in_group(group):
			return true
	return false
