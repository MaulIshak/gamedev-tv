extends Node

@export var spawner: Spawner

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

	get_tree().create_timer(5).timeout.connect(func () -> void:
		next_wave()
	)


func next_wave() -> void:
	if _is_spawning:
		return

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
		var chosen := _pick_weighted_enemy(available)
		if chosen.cost > budget:
			continue

		await get_tree().create_timer(randf_range(min_spawn_delay, max_spawn_delay)).timeout
		spawner.spawn_enemy(chosen.res)
		budget -= chosen.cost
		spawned += 1

		if spawned % batch_size == 0 and budget >= min_cost:
			await get_tree().create_timer(batch_delay).timeout

	_is_spawning = false


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
