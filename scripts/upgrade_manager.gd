extends Node

signal upgraded(id: String, new_level: int)
signal instant_effect_applied(id: String, value: float)

var _levels: Dictionary = {}

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
	return load("res://resources/upgrades/" + id + ".tres") as UpgradeDef

func _load_all_defs() -> Array[UpgradeDef]:
	var dir := DirAccess.open("res://resources/upgrades/")
	if dir == null:
		return []
	var defs: Array[UpgradeDef] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var def := load("res://resources/upgrades/" + file_name) as UpgradeDef
			if def != null and not def.id.is_empty():
				defs.append(def)
		file_name = dir.get_next()
	dir.list_dir_end()
	return defs
