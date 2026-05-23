extends Node

@export var turret_spawn_area: ReferenceRect
@export var turret_scene: PackedScene
@export var turret_parent: Node2D
@export var turret_max_count: int = 4
@export var center_exclusion_radius: float = 64
@export var min_turret_distance: float = 64
@export var max_spawn_attempts: int = 20

var _spawned_turrets: Array[Node2D] = []


func _ready() -> void:
	if turret_spawn_area == null:
		push_warning("wave_manager: turret_spawn_area is null")
	if turret_scene == null:
		push_warning("wave_manager: turret_scene is null")
	if turret_parent == null:
		push_warning("wave_manager: turret_parent is null")

	get_tree().create_timer(3.0).timeout.connect(func () -> void:
		for i in range(turret_max_count):
			spawn_turret()
	)


func spawn_turret() -> void:
	if _spawned_turrets.size() >= turret_max_count:
		return
	if turret_spawn_area == null or turret_scene == null or turret_parent == null:
		return

	var world_rect := _get_world_rect()
	var center := _get_spawn_area_center()

	var turret_pos = _find_valid_position(world_rect, center, true)
	if turret_pos == null:
		turret_pos = _find_valid_position(world_rect, center, false)
	if turret_pos == null:
		turret_pos = _get_random_position_in_rect(world_rect)

	_place_turret(turret_pos)


func _get_world_rect() -> Rect2:
	return Rect2(turret_spawn_area.global_position, turret_spawn_area.size)


func _get_spawn_area_center() -> Vector2:
	return turret_spawn_area.global_position + turret_spawn_area.size / 2.0


func _find_valid_position(rect: Rect2, center: Vector2, check_turrets: bool) -> Variant:
	for _i in max_spawn_attempts:
		var pos := _get_random_position_in_rect(rect)
		if pos.distance_to(center) < center_exclusion_radius:
			continue
		if check_turrets and _is_too_close_to_turrets(pos):
			continue
		return pos
	return null


func _get_random_position_in_rect(rect: Rect2) -> Vector2:
	return Vector2(
		randf_range(rect.position.x, rect.end.x),
		randf_range(rect.position.y, rect.end.y)
	)


func _is_too_close_to_turrets(pos: Vector2) -> bool:
	for turret in _spawned_turrets:
		if pos.distance_to(turret.global_position) < min_turret_distance:
			return true
	return false


func _place_turret(pos: Vector2) -> void:
	var turret := turret_scene.instantiate() as Node2D
	turret.global_position = pos
	turret_parent.add_child(turret)
	_spawned_turrets.append(turret)
