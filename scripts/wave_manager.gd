extends Node

@export var spawner: Spawner
@export var upgrade_ui: Control
@export var connection_manager: PlayerConnectionManager

@export_group("Wave Budget")
@export var base_budget: float = 5.0
@export var budget_per_wave: float = 2.0

@export_group("Spawn Pacing")
@export var min_spawn_delay: float = 0.3
@export var max_spawn_delay: float = 0.6
@export var batch_size: int = 6
@export var batch_delay: float = 3.0

var _current_wave: int = 0
var _is_spawning: bool = false
var _waiting_for_clear: bool = false
var _is_active: bool = false
var _run_id: int = 0

var enemy_data: Array = [{
	"weight": 1.0,
	"cost": 1.0,
	"minimal_wave": 2,
	"res": preload("res://scripts/enemy/resources/small_enemy.tres")
}, {
	"weight": 1.0,
	"cost": 1.0,
	"minimal_wave": 0,
	"res": preload("res://scripts/enemy/resources/normal_enemy.tres")
}, {
	"weight": 3.0,
	"cost": 2.0,
	"minimal_wave": 4,
	"res": preload("res://scripts/enemy/resources/elite_enemy.tres")
}]


func _ready() -> void:
	if spawner == null:
		push_warning("wave_manager: spawner is null")

	if upgrade_ui != null and upgrade_ui.has_signal("upgrade_selected"):
		upgrade_ui.upgrade_selected.connect(func(_id: String) -> void:
			next_wave()
		)


func start_game() -> void:
	_run_id += 1
	_current_wave = 0
	_is_spawning = false
	_waiting_for_clear = false
	_is_active = true
	_clear_runtime_nodes()
	next_wave()


func stop_game() -> void:
	_run_id += 1
	_is_active = false
	_is_spawning = false
	_waiting_for_clear = false
	_current_wave = 0
	_clear_runtime_nodes()


func next_wave() -> void:
	if not _is_active or _is_spawning:
		return

	var run_id := _run_id
	_is_spawning = true
	_current_wave += 1

	for i in range(spawner.turret_max_count):
		spawner.spawn_turret()

	var budget := base_budget + (_current_wave - 1) * budget_per_wave
	var available := _get_available_enemies()
	if available.is_empty():
		_is_spawning = false
		return

	var spawned := 0
	var min_cost := _get_min_cost(available)

	while budget >= min_cost:
		if not _is_active or run_id != _run_id:
			_is_spawning = false
			return

		var chosen := _pick_weighted_enemy(available)
		if chosen.cost > budget:
			continue

		await get_tree().create_timer(randf_range(min_spawn_delay, max_spawn_delay)).timeout
		if not _is_active or run_id != _run_id:
			_is_spawning = false
			return
		spawner.spawn_enemy(chosen.res)
		budget -= chosen.cost
		spawned += 1

		if spawned % batch_size == 0 and budget >= min_cost:
			await get_tree().create_timer(batch_delay).timeout

	if not _is_active or run_id != _run_id:
		_is_spawning = false
		return

	_is_spawning = false
	_waiting_for_clear = true


func _process(_delta: float) -> void:
	if not _is_active or not _waiting_for_clear:
		return
	if _are_all_enemies_dead():
		_waiting_for_clear = false
		if connection_manager != null:
			connection_manager.clear_all_connections()
		if spawner != null:
			spawner.clear_turrets()
			spawner.clear_enemies()
		_clear_explosions()
		if upgrade_ui != null and upgrade_ui.has_method("show_upgrades"):
			upgrade_ui.show_upgrades()


func _clear_runtime_nodes() -> void:
	if connection_manager != null:
		connection_manager.clear_all_connections()
	if spawner != null:
		spawner.clear_turrets()
		spawner.clear_enemies()
	if upgrade_ui != null:
		upgrade_ui.hide()
		var upgrade_player = upgrade_ui.get("player")
		if upgrade_player != null and upgrade_player.has_method("enable_input"):
			upgrade_player.enable_input()
	_clear_explosions()


func _are_all_enemies_dead() -> bool:
	for child in spawner.enemy_parent.get_children():
		if not child.is_queued_for_deletion():
			return false
	return true


func _clear_explosions() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	for child in scene.get_children():
		if child is Explosion:
			child.queue_free()


func _get_available_enemies() -> Array:
	var result: Array = []
	for entry in enemy_data:
		if entry.minimal_wave <= _current_wave:
			result.append(entry)
	return result


func _pick_weighted_enemy(available: Array) -> Dictionary:
	var total_weight := 0.0
	for entry in available:
		total_weight += entry.weight

	var roll := randf() * total_weight
	var accumulated := 0.0
	for entry in available:
		accumulated += entry.weight
		if roll <= accumulated:
			return entry

	return available.back()


func _get_min_cost(available: Array) -> float:
	var min_cost := INF
	for entry in available:
		min_cost = minf(min_cost, entry.cost)
	return min_cost
