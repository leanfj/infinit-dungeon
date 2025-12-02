extends Node
class_name AutoAim

static func find_nearest_enemy(tree: SceneTree, origin: Vector2, max_distance: float = 256.0) -> Node2D:
	var nearest: Node2D = null
	var best_dist := INF
	for node in tree.get_nodes_in_group("enemies"):
		if not (node is Node2D):
			continue
		var e := node as Node2D
		var d := origin.distance_to(e.global_position)
		if d < best_dist and d <= max_distance:
			best_dist = d
			nearest = e
	return nearest

static func set_highlight(enemy: Node, highlighted: bool) -> void:
	if enemy == null:
		return
	# Avoid acting on freed or invalid instances
	if not is_instance_valid(enemy):
		return
	# Prefer dedicated API when available
	if enemy.has_method("set_highlighted"):
		enemy.call("set_highlighted", highlighted)
		return
	# Fallback: modulate tint
	if enemy is CanvasItem:
		var canvas := enemy as CanvasItem
		canvas.modulate = Color(1.0, 1.0, 0.8, canvas.modulate.a) if highlighted else Color(1.0, 1.0, 1.0, canvas.modulate.a)
