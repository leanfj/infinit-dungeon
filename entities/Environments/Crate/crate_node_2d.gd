class_name CrateNode2D
extends Node2D

@export var drop_scenes: Array[PackedScene] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HitBoxArea2D.hit_detected.connect(take_damage)

func take_damage(_amount: int, _origin: Vector2 = Vector2.ZERO) -> void:
	_spawn_drop()
	queue_free()


func _spawn_drop() -> void:
	if not get_parent():
		return
	if drop_scenes.is_empty():
		return
	var scene: PackedScene = drop_scenes[randi() % drop_scenes.size()]
	if scene == null:
		return
	var inst := scene.instantiate()
	get_parent().add_child(inst)
	if inst is Node2D:
		inst.global_position = global_position
