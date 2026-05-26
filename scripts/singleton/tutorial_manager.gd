extends Node

signal tutorial_started
signal tutorial_prompt_changed(message: String)
signal tutorial_completed

const TUTORIAL_CONNECTION_PROMPT := "Tutorial: sambungkan 1 node ke node lain."
const TUTORIAL_SURVIVE_PROMPT := "Tutorial: pertahankan diri sampai musuh mati."
const TUTORIAL_ENEMY_STATS: EnemyStats = preload("res://scripts/enemy/resources/normal_enemy.tres")

enum TutorialState { IDLE, WAITING_FOR_CONNECTION, WAITING_FOR_ENEMY, COMPLETED }

var tutorial_completed_this_session: bool = false
var _state := TutorialState.IDLE
var _spawner: Spawner = null
var _wave_manager: Node = null
var _connection_manager: PlayerConnectionManager = null
var _overlay: Node = null
var _tutorial_enemy: Node2D = null


func should_run_tutorial() -> bool:
	return not tutorial_completed_this_session


func is_active() -> bool:
	return _state == TutorialState.WAITING_FOR_CONNECTION or _state == TutorialState.WAITING_FOR_ENEMY


func start_tutorial(spawner: Spawner, wave_manager: Node, connection_manager: PlayerConnectionManager, overlay: Node) -> void:
	if tutorial_completed_this_session or is_active():
		return

	_spawner = spawner
	_wave_manager = wave_manager
	_connection_manager = connection_manager
	_overlay = overlay
	_state = TutorialState.WAITING_FOR_CONNECTION

	_connect_signals()
	_show_prompt(TUTORIAL_CONNECTION_PROMPT)
	tutorial_started.emit()


func cancel_tutorial() -> void:
	_disconnect_signals()
	_clear_spawned_enemy()
	_hide_prompt()
	_state = TutorialState.IDLE
	_spawner = null
	_wave_manager = null
	_connection_manager = null
	_overlay = null


func _connect_signals() -> void:
	if _connection_manager != null and not _connection_manager.lightning_created.is_connected(_on_lightning_created):
		_connection_manager.lightning_created.connect(_on_lightning_created)


func _disconnect_signals() -> void:
	if _connection_manager != null and _connection_manager.lightning_created.is_connected(_on_lightning_created):
		_connection_manager.lightning_created.disconnect(_on_lightning_created)


func _on_lightning_created(_from_tower: Node2D, _to_tower: Node2D) -> void:
	if _state != TutorialState.WAITING_FOR_CONNECTION:
		return

	_state = TutorialState.WAITING_FOR_ENEMY
	_show_prompt(TUTORIAL_SURVIVE_PROMPT)
	_spawn_tutorial_enemy()


func _spawn_tutorial_enemy() -> void:
	if _spawner == null:
		push_warning("TutorialManager: spawner is null")
		return

	_clear_spawned_enemy()
	_tutorial_enemy = _spawner.spawn_enemy(TUTORIAL_ENEMY_STATS)
	if not is_instance_valid(_tutorial_enemy):
		push_warning("TutorialManager: failed to spawn tutorial enemy")
		_complete_tutorial()
		return

	if _tutorial_enemy.has_signal("died") and not _tutorial_enemy.died.is_connected(_on_tutorial_enemy_died):
		_tutorial_enemy.died.connect(_on_tutorial_enemy_died)


func _on_tutorial_enemy_died() -> void:
	if _state != TutorialState.WAITING_FOR_ENEMY:
		return

	_complete_tutorial()


func _complete_tutorial() -> void:
	tutorial_completed_this_session = true
	_state = TutorialState.COMPLETED
	_disconnect_signals()
	_hide_prompt()
	_clear_spawned_enemy()

	var wave_manager := _wave_manager
	cancel_tutorial()
	if wave_manager != null and wave_manager.has_method("start_game"):
		wave_manager.call_deferred("start_game")

	tutorial_completed.emit()


func _clear_spawned_enemy() -> void:
	if is_instance_valid(_tutorial_enemy):
		_tutorial_enemy.queue_free()
	_tutorial_enemy = null


func _show_prompt(message: String) -> void:
	tutorial_prompt_changed.emit(message)
	if _overlay != null and _overlay.has_method("show_message"):
		_overlay.call("show_message", message)


func _hide_prompt() -> void:
	if _overlay != null and _overlay.has_method("hide_message"):
		_overlay.call("hide_message")
