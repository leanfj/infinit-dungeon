class_name HitBoxArea2D
extends Area2D


signal hit_detected(amount: int, origin: Vector2)


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


func take_damage(amount: int, origin: Vector2 = Vector2.ZERO) -> void:
	print("HitBoxArea2D took damage: %d" % amount)
	emit_signal("hit_detected", amount, origin)
