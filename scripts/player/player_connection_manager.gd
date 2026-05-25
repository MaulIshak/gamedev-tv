class_name PlayerConnectionManager extends Node

const ELECTRIC_SHOCK_SFX: AudioStream = preload("res://assets/audio/sfx/electric_shock.mp3")
const METALLIC_CLING_SFX: AudioStream = preload("res://assets/audio/sfx/cling.mp3")

enum State {NO_CABLE, HAS_PLAYER_CABLE}

@export var cable_scene: PackedScene
@export var lightning_scene: PackedScene
@export var cable_count: int = 2
@export var cable_spacing: float = 4.0
@export var connection_parent: Node2D
@export var connection_duration: float = 10.0

var _state := State.NO_CABLE
var _cable_tower: Node2D = null
var _player_cables: Array[Connection] = []
var _lightning_connections: Array[Connection] = []
var _electric_shock_player: AudioStreamPlayer = null

func _ready() -> void:
	var player := get_parent() as Player

	await player.ready

	if player.tower_detector:
		player.tower_detector.area_entered.connect(_on_tower_entered)

func _get_parent_node() -> Node2D:
	if connection_parent:
		return connection_parent
	return get_parent().get_parent()

func _process(_delta: float) -> void:
	if _state == State.HAS_PLAYER_CABLE and not is_instance_valid(_cable_tower):
		_destroy_player_cables()
		_state = State.NO_CABLE
		_cable_tower = null

	for i in range(_lightning_connections.size() - 1, -1, -1):
		var conn := _lightning_connections[i]
		if not is_instance_valid(conn):
			_lightning_connections.remove_at(i)
			continue
		if not is_instance_valid(conn.start_pos) or not is_instance_valid(conn.end_pos):
			conn.queue_free()
			_lightning_connections.remove_at(i)

func _on_tower_entered(tower_area: Area2D) -> void:
	var tower := tower_area.get_parent() as Node2D

	match _state:
		State.NO_CABLE:
			if not tower.is_connected_tower:
				_create_player_cables(tower)
		State.HAS_PLAYER_CABLE:
			if not is_instance_valid(_cable_tower):
				_destroy_player_cables()
				_state = State.NO_CABLE
				_cable_tower = null
				return
			if tower != _cable_tower:
				_create_lightning_between(_cable_tower, tower)

func _create_player_cables(tower: Node2D) -> void:
	_state = State.HAS_PLAYER_CABLE
	_cable_tower = tower
	if SfxManager != null:
		SfxManager.play_sfx_once(METALLIC_CLING_SFX, &"SFX", 0.0, false, true)

	var parent := _get_parent_node()
	for i in range(cable_count):
		var cable: Connection = cable_scene.instantiate()
		cable.start_pos = tower
		cable.end_pos = get_parent()
		cable.end_offset = Vector2(0.0, -16.0)
		var half := float(cable_count - 1) / 2.0
		cable.offset = Vector2((float(i) - half) * cable_spacing, 0.0)
		parent.add_child(cable)
		_player_cables.append(cable)

func _create_lightning_between(from_tower: Node2D, to_tower: Node2D) -> void:
	_state = State.NO_CABLE
	_cable_tower = null

	_destroy_player_cables()

	var existing_conns: Array[Connection] = []
	var max_time_left: float = 0.0
	for i in range(_lightning_connections.size() - 1, -1, -1):
		var conn := _lightning_connections[i]
		if not is_instance_valid(conn):
			_lightning_connections.remove_at(i)
			continue
		if conn.start_pos == from_tower or conn.end_pos == from_tower or \
		   conn.start_pos == to_tower or conn.end_pos == to_tower:
			existing_conns.append(conn)
			max_time_left = max(max_time_left, conn.get_time_left())

	var synced_duration := max_time_left + connection_duration

	for conn in existing_conns:
		conn.set_timer(synced_duration)

	from_tower.is_connected_tower = true
	to_tower.is_connected_tower = true
	if SfxManager != null:
		_play_electric_shock_sfx()
		SfxManager.play_sfx_once(METALLIC_CLING_SFX, &"SFX", 0.0, false, true)

	var lightning: Connection = lightning_scene.instantiate()
	lightning.start_pos = from_tower
	lightning.end_pos = to_tower
	lightning.start_timer(synced_duration)
	lightning.expired.connect(_on_connection_expired)
	# connect visual_finished so manager can stop looping SFX exactly when visuals end
	if lightning.has_signal("visual_finished"):
		lightning.visual_finished.connect(_on_lightning_visual_finished)

	if lightning.damage_zone != null:
		lightning.damage_zone.damage += int(UpgradeManager.get_stat_add("lightning_damage"))
		lightning.damage_zone.slow_amount += UpgradeManager.get_stat_add("slow_power")

	_get_parent_node().add_child(lightning)
	_lightning_connections.append(lightning)

func _on_connection_expired(from_tower: Node2D, to_tower: Node2D) -> void:
	for i in range(_lightning_connections.size() - 1, -1, -1):
		var conn := _lightning_connections[i]
		if not is_instance_valid(conn):
			_lightning_connections.remove_at(i)
			continue
		if conn.start_pos == from_tower and conn.end_pos == to_tower:
			_lightning_connections.remove_at(i)
			break

	if is_instance_valid(from_tower):
		from_tower.on_connection_expired()
	if is_instance_valid(to_tower):
		to_tower.on_connection_expired()

	if not _tower_has_active_connection(from_tower):
		from_tower.is_connected_tower = false
	if not _tower_has_active_connection(to_tower):
		to_tower.is_connected_tower = false

	if _lightning_connections.is_empty():
		_stop_electric_shock_sfx()


func _on_lightning_visual_finished(from_tower: Node2D, to_tower: Node2D) -> void:
	# Remove matching or invalid connections and stop SFX when none remain
	for i in range(_lightning_connections.size() - 1, -1, -1):
		var conn := _lightning_connections[i]
		if not is_instance_valid(conn) or (conn.start_pos == from_tower and conn.end_pos == to_tower):
			_lightning_connections.remove_at(i)

	if _lightning_connections.is_empty():
		_stop_electric_shock_sfx()

func _tower_has_active_connection(tower: Node2D) -> bool:
	for i in range(_lightning_connections.size() - 1, -1, -1):
		var conn := _lightning_connections[i]
		if not is_instance_valid(conn):
			_lightning_connections.remove_at(i)
			continue
		if conn.start_pos == tower or conn.end_pos == tower:
			return true
	return false

func _destroy_player_cables() -> void:
	for cable in _player_cables:
		if is_instance_valid(cable):
			cable.queue_free()
	_player_cables.clear()

func clear_all_connections() -> void:
	_destroy_player_cables()

	for i in range(_lightning_connections.size() - 1, -1, -1):
		var conn := _lightning_connections[i]
		if not is_instance_valid(conn):
			_lightning_connections.remove_at(i)
			continue
		if is_instance_valid(conn.start_pos):
			conn.start_pos.is_connected_tower = false
		if is_instance_valid(conn.end_pos):
			conn.end_pos.is_connected_tower = false
		conn.queue_free()
		_lightning_connections.remove_at(i)

	_stop_electric_shock_sfx()

	_state = State.NO_CABLE
	_cable_tower = null


func _play_electric_shock_sfx() -> void:
	if SfxManager == null:
		return

	if is_instance_valid(_electric_shock_player) and _electric_shock_player.playing:
		return

	print("[PlayerConnectionManager] play electric shock sfx")
	_electric_shock_player = SfxManager.play_sfx(ELECTRIC_SHOCK_SFX, &"SFX", 0.0, false, true)


func _stop_electric_shock_sfx() -> void:
	if not is_instance_valid(_electric_shock_player):
		_electric_shock_player = null
		return

	print("[PlayerConnectionManager] stop electric shock sfx")

	if SfxManager != null:
		# Force-stop any players playing the electric shock stream to ensure immediate cut
		SfxManager.stop_sfx_by_stream(ELECTRIC_SHOCK_SFX)
	else:
		_electric_shock_player.stop()

	_electric_shock_player = null
