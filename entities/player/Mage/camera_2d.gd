extends Camera2D

@export var terrain_path: NodePath = NodePath("../TerrainManagerNode2D")
@export var wall_tilemap_name: String = "WallTileMapLayer"

var _current_limits: Rect2 = Rect2()
var _current_room: Node2D = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_limits_for_room()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Update limits if we leave the current room bounds.
	if not _current_limits.has_point(global_position):
		_update_limits_for_room()


func _update_limits_for_room() -> void:
	var terrain := _get_terrain()
	if terrain == null:
		return

	# Find the room that currently contains the player
	var player_global := global_position
	var room := _find_room_containing_point(terrain, player_global)
	if room == null:
		return

	_current_room = room
	var wall_tilemap := room.get_node_or_null(wall_tilemap_name)
	if wall_tilemap and wall_tilemap is TileMapLayer:
		var rect := _get_used_rect_global(wall_tilemap)
		_apply_limits(rect)


func _get_terrain() -> Node:
	if terrain_path != NodePath("") and get_node_or_null(terrain_path):
		return get_node(terrain_path)
	# fallback: first node in group "terrain_manager"
	return get_tree().get_first_node_in_group("terrain_manager")


func _find_room_containing_point(terrain: Node, point: Vector2) -> Node2D:
	for child in terrain.get_children():
		if child is Node2D:
			var wall_tilemap := child.get_node_or_null(wall_tilemap_name)
			if wall_tilemap and wall_tilemap is TileMapLayer:
				var rect := _get_used_rect_global(wall_tilemap)
				if rect.has_point(point):
					return child
	return null


func _get_used_rect_global(tilemap: TileMapLayer) -> Rect2:
	var used_rect := tilemap.get_used_rect()
	var tile_size: Vector2 = Vector2.ZERO
	if tilemap.tile_set:
		tile_size = tilemap.tile_set.tile_size
	var local_rect := Rect2(
		Vector2(used_rect.position) * tile_size + tile_size * -0.5,
		Vector2(used_rect.size) * tile_size
	)
	return Rect2(
		tilemap.to_global(local_rect.position),
		local_rect.size
	)


func _apply_limits(rect: Rect2) -> void:
	_current_limits = rect
	limit_left = int(rect.position.x)
	limit_top = int(rect.position.y)
	limit_right = int(rect.position.x + rect.size.x)
	limit_bottom = int(rect.position.y + rect.size.y)
