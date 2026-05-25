class_name Spawner extends Node

# -- Turret exports -------------------------------------------------

@export_group("Turret Setup")
@export var turret_spawn_area: ReferenceRect
@export var turret_scene: PackedScene
@export var turret_parent: Node2D
@export var turret_max_count: int = 4
@export var center_exclusion_radius: float = 64.0
@export var min_turret_distance: float = 64.0
@export var max_spawn_attempts: int = 20
@export var tile_map: TileMapLayer

var _spawned_turrets: Array[Node2D] = []

# -- Enemy exports --------------------------------------------------
@export_group("Enemy Setup")
@export var enemy_spawn_area: ReferenceRect
@export var enemy_scene: PackedScene
@export var enemy_parent: Node2D
@export var enemy_movement_target: Node2D
@export var enemy_max_count: int = 10
@export var enemy_edge_margin: float = 32.0
@export var min_enemy_distance: float = 32.0
@export var enemy_max_spawn_attempts: int = 20

var _spawned_enemies: Array[Node2D] = []

const NORMAL_ENEMY_STATS: EnemyStats = preload("res://scripts/enemy/resources/normal_enemy.tres")

# -- Lifecycle ------------------------------------------------------

func _ready() -> void:
	if turret_spawn_area == null:
		push_warning("turret_spawn_area is null")
	if turret_scene == null:
		push_warning("turret_scene is null")
	if turret_parent == null:
		push_warning("turret_parent is null")
	if enemy_spawn_area == null:
		push_warning("enemy_spawn_area is null")
	if enemy_scene == null:
		push_warning("enemy_scene is null")
	if enemy_parent == null:
		push_warning("enemy_parent is null")
	if enemy_movement_target == null:
		push_warning("enemy_movement_target is null")


# -- Turret spawning ------------------------------------------------

func spawn_turret() -> void:
	if _spawned_turrets.size() >= turret_max_count:
		return
	if turret_spawn_area == null or turret_scene == null or turret_parent == null or tile_map == null:
		return
	
	for cell: Vector2i in tile_map.get_used_cells():
		var source_id := tile_map.get_cell_source_id(cell)
		var atlas_coords := tile_map.get_cell_atlas_coords(cell)
		var alternative := tile_map.get_cell_alternative_tile(cell)

		print("cell:", cell)
		print("source:", source_id)
		print("atlas:", atlas_coords)
		print("alternative:", alternative)

	var rect := _get_world_rect(turret_spawn_area)
	var center := _get_rect_center(turret_spawn_area)

	var generate = func() -> Vector2: return _get_random_position_in_rect(rect)
	var validate = func(p: Vector2) -> bool:
		return p.distance_to(center) >= center_exclusion_radius and not _is_too_close_to_any(p, _spawned_turrets, min_turret_distance)

	var pos = _find_valid_position(max_spawn_attempts, generate, validate)
	if pos == null:
		validate = func(p: Vector2) -> bool: return p.distance_to(center) >= center_exclusion_radius
		pos = _find_valid_position(max_spawn_attempts, generate, validate)
	if pos == null:
		pos = _get_random_position_in_rect(rect)

	# _place_turret(pos)
	var snapped_pos = _snap_global_position_to_tile_center(pos)
	if snapped_pos == null:
		return

	_place_turret(snapped_pos)

func _snap_global_position_to_tile_center(global_pos: Vector2) -> Variant:
	if tile_map == null:
		return null

	var local_pos: Vector2 = tile_map.to_local(global_pos)

	var cell: Vector2i = tile_map.local_to_map(local_pos)

	var source_id := tile_map.get_cell_source_id(cell)
	if source_id == -1:
		return null

	var cell_center_local: Vector2 = tile_map.map_to_local(cell)

	var cell_center_global: Vector2 = tile_map.to_global(cell_center_local)

	return cell_center_global

func _place_turret(pos: Vector2) -> void:
	var turret := turret_scene.instantiate() as Node2D

	pos.y -= 8;

	turret.global_position = pos
	turret_parent.add_child(turret)
	_spawned_turrets.append(turret)
	
	await get_tree().create_timer(0.2).timeout
	
	if is_instance_valid(turret):
		turret.show_turret()

# -- Enemy spawning -------------------------------------------------

func spawn_enemy(stats: EnemyStats) -> void:
	if _spawned_enemies.size() >= enemy_max_count:
		return
	if enemy_spawn_area == null or enemy_scene == null or enemy_parent == null or enemy_movement_target == null or stats == null:
		return

	var rect := _get_world_rect(enemy_spawn_area)

	var generate = func() -> Vector2: return _get_random_position_near_edge(rect, enemy_edge_margin)
	var validate = func(p: Vector2) -> bool:
		return not _is_too_close_to_any(p, _spawned_enemies, min_enemy_distance)

	var pos = _find_valid_position(enemy_max_spawn_attempts, generate, validate)
	if pos == null:
		validate = func(_p: Vector2) -> bool: return true
		pos = _find_valid_position(enemy_max_spawn_attempts, generate, validate)
	if pos == null:
		pos = _get_random_position_near_edge(rect, enemy_edge_margin)

	_place_enemy(pos, stats)


func _place_enemy(pos: Vector2, stats: EnemyStats) -> void:
	var enemy := enemy_scene.instantiate()
	enemy.global_position = pos
	enemy.movement_target = enemy_movement_target
	enemy.enemy_stats = stats
	enemy_parent.add_child(enemy)
	_spawned_enemies.append(enemy)

func clear_turrets() -> void:
	for turret in _spawned_turrets:
		if is_instance_valid(turret):
			turret.queue_free()
	_spawned_turrets.clear()

func clear_enemies() -> void:
	for enemy in _spawned_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_spawned_enemies.clear()

# -- Generic placement helpers --------------------------------------

func _get_world_rect(area: ReferenceRect) -> Rect2:
	return Rect2(area.global_position, area.size)


func _get_rect_center(area: ReferenceRect) -> Vector2:
	return area.global_position + area.size / 2.0


func _get_random_position_in_rect(rect: Rect2) -> Vector2:
	return Vector2(
		randf_range(rect.position.x, rect.end.x),
		randf_range(rect.position.y, rect.end.y)
	)


func _get_random_position_near_edge(rect: Rect2, margin: float) -> Vector2:
	var m := clampf(margin, 0.0, minf(rect.size.x, rect.size.y) / 2.0)
	match randi() % 4:
		0:
			return Vector2(randf_range(rect.position.x, rect.end.x), randf_range(rect.position.y, rect.position.y + m))
		1:
			return Vector2(randf_range(rect.position.x, rect.end.x), randf_range(rect.end.y - m, rect.end.y))
		2:
			return Vector2(randf_range(rect.position.x, rect.position.x + m), randf_range(rect.position.y, rect.end.y))
		_:
			return Vector2(randf_range(rect.end.x - m, rect.end.x), randf_range(rect.position.y, rect.end.y))


func _find_valid_position(attempts: int, generate: Callable, validate: Callable) -> Variant:
	for _i in attempts:
		var pos: Vector2 = generate.call()
		if validate.call(pos):
			return pos
	return null


func _is_too_close_to_any(pos: Vector2, nodes: Array[Node2D], min_dist: float) -> bool:
	for i in range(nodes.size() - 1, -1, -1):
		if not is_instance_valid(nodes[i]):
			nodes.remove_at(i)
			continue
		if pos.distance_to(nodes[i].global_position) < min_dist:
			return true
	return false
