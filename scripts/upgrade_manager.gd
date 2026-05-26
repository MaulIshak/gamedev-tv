extends Node

signal upgraded(id: String, new_level: int)
signal instant_effect_applied(id: String, value: float)

const UPGRADE_IDS: Array[String] = [
	"dash_cooldown",
	"enemy_immunity",
	"heal",
	"lightning_damage",
	"max_hp",
	"shockwave_damage",
	"slow_power",
	"walk_speed"
]

var _levels: Dictionary = {}

func _ready() -> void:
	# Seed the random number generator so builds are truly random upon launch
	randomize()


func reset() -> void:
	_levels.clear()

func get_level(id: String) -> int:
	return _levels.get(id, 0)

func get_stat_add(id: String) -> float:
	var def := _get_def(id)
	if def == null:
		return 0.0
	return def.get_value_at_level(get_level(id))

func can_upgrade(id: String) -> bool:
	var def := _get_def(id)
	if def == null:
		return false
	return get_level(id) < def.max_level

func apply_upgrade(id: String) -> bool:
	if not can_upgrade(id):
		return false

	var def := _get_def(id)
	var new_level := get_level(id) + 1
	_levels[id] = new_level

	if def.apply_type == UpgradeDef.ApplyType.INSTANT:
		instant_effect_applied.emit(id, def.value_per_level)

	upgraded.emit(id, new_level)
	return true

func get_random_upgrades(count: int = 3) -> Array[UpgradeDef]:
	var all_defs := _load_all_defs()
	var pool: Array[UpgradeDef] = []
	for def in all_defs:
		if can_upgrade(def.id):
			pool.append(def)

	pool.shuffle()
	var picked: Array[UpgradeDef] = []
	for i in range(min(count, pool.size())):
		picked.append(pool[i])

	while picked.size() < count:
		picked.append(_get_def("heal"))

	return picked

func _get_def(id: String) -> UpgradeDef:
	var path := "res://resources/upgrades/" + id + ".tres"
	return load(path) as UpgradeDef

func _load_all_defs() -> Array[UpgradeDef]:
	var defs: Array[UpgradeDef] = []
	for id in UPGRADE_IDS:
		var def := _get_def(id)
		if def != null and not def.id.is_empty():
			defs.append(def)
	return defs
