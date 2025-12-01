class_name CrateNode2D
extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HitBoxArea2D.hit_detected.connect(take_damage)

func take_damage(_amount: int, _origin: Vector2 = Vector2.ZERO) -> void:
	if get_parent():
		var flask_scene := preload("res://entities/Environments/Flasks/flask_red_node_2d.tscn")
		var flask := flask_scene.instantiate()
		get_parent().add_child(flask)
		if flask is Node2D:
			flask.global_position = global_position
	queue_free()
