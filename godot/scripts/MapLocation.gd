extends Node2D

@export var scene_id := ""
@export var title := ""
@export_multiline var subtitle := ""
@export_multiline var default_status := ""
@export var map_size := Vector2(1254, 1254)

func get_spawn_position(spawn_name: String) -> Vector2:
	var spawns := get_node_or_null("SpawnPoints")
	if spawns != null:
		var spawn := spawns.get_node_or_null(spawn_name)
		if spawn is Node2D:
			return spawn.global_position

	return global_position + get_world_size() / 2.0


func get_world_size() -> Vector2:
	return Vector2(map_size.x * abs(global_scale.x), map_size.y * abs(global_scale.y))


func get_portals() -> Array:
	return _area_children("Portals")


func get_characters() -> Array:
	return _area_children("Characters")


func has_walkable_areas() -> bool:
	return not get_walkable_areas().is_empty()


func is_position_walkable(world_position: Vector2) -> bool:
	var walkable_areas := get_walkable_areas()
	if walkable_areas.is_empty():
		return true

	for area in walkable_areas:
		if Geometry2D.is_point_in_polygon(area.to_local(world_position), area.polygon):
			return true

	return false


func get_walkable_areas() -> Array:
	var areas := []
	var container := get_node_or_null("WalkableAreas")
	if container == null:
		return areas

	for child in container.get_children():
		if child is Polygon2D:
			areas.append(child)
	return areas


func _area_children(container_name: String) -> Array:
	var areas := []
	var container := get_node_or_null(container_name)
	if container == null:
		return areas

	for child in container.get_children():
		if child is Area2D:
			areas.append(child)
	return areas
