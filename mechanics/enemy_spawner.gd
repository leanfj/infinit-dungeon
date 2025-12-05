extends Node2D
class_name EnemySpawner

@export_category("Spawner")
@export var enemy_scenes: Array[PackedScene] = []
@export var max_alive: int = 3
@export var initial_spawn: int = 3
@export var max_total_spawns: int = -1 # -1 = infinito
@export var respawn_delay: float = 1.5
@export var spawn_on_ready: bool = true
@export var spawn_parent_path: NodePath
@export var target_path: NodePath
@export var spawn_point_limits: Dictionary = {} # Ex.: { "SpawnPoint1": 3 }
@export var min_spawn_spacing: float = 8.0
@export var spawn_position_jitter: float = 4.0
@export var key_scene: PackedScene

@export_category("Spawn Points")
@export var random_spawn: bool = true

@onready var _respawn_timer: Timer = _get_respawn_timer()
var _alive: Array[Node] = []
var _spawn_points: Array[Marker2D] = []
var _respawn_queue: int = 0
var _spawn_index: int = 0
var _spawn_bag: Array[int] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _spawned_total: int = 0
var _spawned_by_point: Dictionary = {}
var _last_spawn_point_index: int = -1
var _point_active: Dictionary = {} # idx -> Node
var _enemy_point: Dictionary = {} # enemy -> idx
var _cleared_emitted: bool = false


func _ready() -> void:
	_rng.randomize()
	_collect_spawn_points()
	if _respawn_timer:
		_respawn_timer.timeout.connect(_on_respawn_timeout)

	call_deferred("_do_initial_spawn")


func _get_respawn_timer() -> Timer:
	var timer := get_node_or_null("RespawnTimer") as Timer
	if timer == null:
		timer = Timer.new()
		timer.name = "RespawnTimer"
		timer.one_shot = true
		add_child(timer)
	timer.one_shot = true
	return timer


func _collect_spawn_points() -> void:
	_spawn_points.clear()
	_collect_from(self)
	_refill_spawn_bag()
	_spawned_by_point.clear()
	_point_active.clear()
	_enemy_point.clear()


func _collect_from(node: Node) -> void:
	for child in node.get_children():
		if child is Marker2D:
			_spawn_points.append(child)
		_collect_from(child)


func _refill_spawn_bag() -> void:
	_spawn_bag.clear()
	if _spawn_points.is_empty():
		return
	for i in range(_spawn_points.size()):
		if _point_available(i):
			_spawn_bag.append(i)
	if random_spawn:
		_spawn_bag.shuffle()


func _do_initial_spawn() -> void:
	_collect_spawn_points()
	if spawn_on_ready:
		var count: int = min(initial_spawn, max_alive)
		var remaining := _remaining_spawns()
		if remaining >= 0:
			count = min(count, remaining)
		for i in range(count):
			_spawn_enemy()


func _spawn_enemy() -> bool:
	if enemy_scenes.is_empty():
		return false
	if _alive.size() >= max_alive:
		return false
	if not _can_spawn_more():
		return false

	var scene: PackedScene = enemy_scenes[_rng.randi_range(0, enemy_scenes.size() - 1)]
	if scene == null:
		return false
	var enemy: Node = scene.instantiate()
	var parent: Node = _get_spawn_parent()
	if parent == null or enemy == null:
		return false

	var point_idx := _pick_spawn_point_index()
	if point_idx == -1:
		return false

	parent.add_child(enemy)
	if enemy is Node2D:
		var pos := _pick_spawn_position(point_idx)
		enemy.global_position = _find_free_position(pos)
		_increment_point_spawn(point_idx)
		_mark_point_active(point_idx, enemy)
	if target_path != NodePath("") and _can_set_player_path(enemy):
		enemy.set("_player_path", target_path)

	_alive.append(enemy)
	_spawned_total += 1
	enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy))
	return true


func _get_spawn_parent() -> Node:
	if spawn_parent_path != NodePath("") and has_node(spawn_parent_path):
		return get_node(spawn_parent_path)
	if get_parent():
		return get_parent()
	return self


func _pick_spawn_position(idx: int = -1) -> Vector2:
	if idx >= 0 and idx < _spawn_points.size():
		_last_spawn_point_index = idx
		return _spawn_points[idx].global_position
	_last_spawn_point_index = -1
	if _spawn_points.is_empty():
		return global_position
	if random_spawn:
		if _spawn_bag.is_empty():
			_refill_spawn_bag()
		if _spawn_bag.is_empty():
			return global_position
		var idx_bag: int = _spawn_bag.pop_back()
		if _point_available(idx_bag):
			_last_spawn_point_index = idx_bag
			return _spawn_points[idx_bag].global_position
	# sequencial ou fallback
	var tries: int = _spawn_points.size()
	while tries > 0:
		var idx_seq: int = _spawn_index % _spawn_points.size()
		_spawn_index += 1
		if _point_available(idx_seq):
			_last_spawn_point_index = idx_seq
			return _spawn_points[idx_seq].global_position
		tries -= 1
	return global_position


func _on_enemy_tree_exited(enemy: Node) -> void:
	var idx: int = int(_enemy_point.get(enemy, -1))
	if idx != -1:
		_enemy_point.erase(enemy)
		_point_active.erase(idx)

	_alive.erase(enemy)
	if _can_spawn_more() and _has_available_point():
		_respawn_queue += 1
		_start_respawn_timer()
	elif _alive.is_empty():
		_emit_cleared()
		queue_free()


func _start_respawn_timer() -> void:
	if respawn_delay <= 0.0:
		_on_respawn_timeout()
		return
	if _respawn_timer and _respawn_timer.is_stopped():
		_respawn_timer.start(respawn_delay)


func _on_respawn_timeout() -> void:
	while _respawn_queue > 0 and _alive.size() < max_alive and _can_spawn_more() and _has_available_point():
		_respawn_queue -= 1
		_spawn_enemy()

	if _respawn_queue > 0 and _alive.size() < max_alive and _respawn_timer:
		_respawn_timer.start(respawn_delay)
	elif _respawn_queue == 0 and _alive.is_empty() and not _can_spawn_more():
		_emit_cleared()
		queue_free()


func _can_set_player_path(enemy: Object) -> bool:
	if enemy == null:
		return false
	for prop in enemy.get_property_list():
		if prop.name == "_player_path":
			return true
	return false


func _can_spawn_more() -> bool:
	if max_total_spawns < 0:
		return true
	return _spawned_total < max_total_spawns


func _remaining_spawns() -> int:
	if max_total_spawns < 0:
		return -1
	return max_total_spawns - _spawned_total


func _point_limit(idx: int) -> int:
	if idx < 0 or idx >= _spawn_points.size():
		return -1
	var name: String = _spawn_points[idx].name
	if spawn_point_limits.has(name):
		return int(spawn_point_limits[name])
	return -1


func _point_can_spawn(idx: int) -> bool:
	var limit := _point_limit(idx)
	if limit < 0:
		return true
	return _spawned_by_point.get(idx, 0) < limit


func _point_available(idx: int) -> bool:
	if _point_active.has(idx):
		return false
	return _point_can_spawn(idx)


func _increment_point_spawn(idx: int) -> void:
	_spawned_by_point[idx] = _spawned_by_point.get(idx, 0) + 1


func _mark_point_active(idx: int, enemy: Node) -> void:
	_point_active[idx] = enemy
	_enemy_point[enemy] = idx


func _pick_spawn_point_index() -> int:
	if _spawn_points.is_empty():
		return -1
	if random_spawn:
		if _spawn_bag.is_empty():
			_refill_spawn_bag()
		while not _spawn_bag.is_empty():
			var idx: int = int(_spawn_bag.pop_back())
			if _point_available(idx):
				return idx
	# sequential fallback
	var tries: int = _spawn_points.size()
	while tries > 0:
		var idx_seq: int = _spawn_index % _spawn_points.size()
		_spawn_index += 1
		if _point_available(idx_seq):
			return idx_seq
		tries -= 1
	return -1


func _has_available_point() -> bool:
	for i in range(_spawn_points.size()):
		if _point_available(i):
			return true
	return false

func _last_enemy_global_position() -> Vector2:
	if _last_spawn_point_index >=0 and _last_spawn_point_index < _spawn_points.size():
		return _spawn_points[_last_spawn_point_index].global_position
	return global_position

func _emit_cleared() -> void:
	if _cleared_emitted:
		return
	_cleared_emitted = true
	_spawn_key_drop()


func _spawn_key_drop() -> void:
	if key_scene == null or get_tree() == null:
		return
	var key := key_scene.instantiate()
	if key == null:
		return
	var parent := _get_spawn_parent()
	if parent == null:
		return
	parent.add_child(key)
	# var player := get_tree().get_first_node_in_group("player") if get_tree() else null
	# if player and player is Node2D:
	# 	#precisamos garantir que a posicao nao seja exatamente a do player e nem fora da tela ou algo assim
	# 	# var offset := Vector2(20, 0)
	# 	# key.global_position = player.global_position + offset

	# 	var offset := Vector2(
	# 		_rng.randf_range(-25.0, 25.0),
	# 		_rng.randf_range(-25.0, 25.0)
	# 	)

	# 	key.global_position = player.global_position + offset
		
	# elif parent is Node2D:
	key.global_position = _last_enemy_global_position()

func _find_free_position(base_pos: Vector2) -> Vector2:
	if min_spawn_spacing <= 0.0:
		return base_pos

	# Try a few jittered offsets to avoid stacking
	for i in range(5):
		var offset := Vector2.ZERO
		if spawn_position_jitter > 0.0:
			offset = Vector2(
				_rng.randf_range(-spawn_position_jitter, spawn_position_jitter),
				_rng.randf_range(-spawn_position_jitter, spawn_position_jitter)
			)
		var candidate := base_pos + offset
		if _is_position_clear(candidate):
			return candidate

	return base_pos


func _is_position_clear(pos: Vector2) -> bool:
	for node in _alive:
		if node is Node2D:
			if node.global_position.distance_to(pos) < min_spawn_spacing:
				return false
	return true
