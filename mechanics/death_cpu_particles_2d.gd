extends CPUParticles2D
class_name DeathCpuParticles2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	emitting = true

func _process(delta: float) -> void:
	if !emitting:
		queue_free()