extends Node2D

const CAMERA_TRANSITION_DURATION := 0.28
const GAMEPLAY_ZOOM_MULTIPLIER := 1.08
enum GameState {MAIN_MENU, PLAYING, PAUSED, GAME_OVER}

@onready var crt_screen: ColorRect = $CRTScreen
@onready var main_menu = $MainMenu
@onready var settings_screen = $SettingsScreen
@onready var credits_screen = $CreditsScreen
@onready var pause_menu = $PauseMenu
@onready var game_over_menu = $GameOverMenu
@onready var wave_manager = $"../wave_manager"

var gameplay_camera: Camera2D
var player: Player

var _return_screen: Control
var _state := GameState.MAIN_MENU
var _menu_camera_zoom: Vector2 = Vector2.ONE
var _gameplay_camera_zoom: Vector2 = Vector2.ONE
var _camera_tween: Tween
var _is_transitioning := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	gameplay_camera = get_parent().get_node_or_null("Camera2D") as Camera2D
	player = get_parent().get_node_or_null("Player") as Player
	if gameplay_camera == null:
		push_warning("gameplay_menu_controller: Camera2D not found")
	else:
		_menu_camera_zoom = gameplay_camera.zoom
		_gameplay_camera_zoom = _menu_camera_zoom * GAMEPLAY_ZOOM_MULTIPLIER
	_connect_menus()
	_connect_gameplay()
	_enter_main_menu(false)
	_show_only(main_menu)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		if _state == GameState.PAUSED:
			_resume_game()
		elif _state == GameState.PLAYING:
			_open_pause_menu()


func _connect_menus() -> void:
	main_menu.start_requested.connect(_start_game)
	main_menu.settings_requested.connect(_open_settings.bind(main_menu))
	main_menu.credits_requested.connect(_open_credits.bind(main_menu))
	main_menu.quit_requested.connect(_quit_game)

	pause_menu.resume_requested.connect(_resume_game)
	pause_menu.settings_requested.connect(_open_settings.bind(pause_menu))
	pause_menu.main_menu_requested.connect(_return_to_main_menu)

	game_over_menu.main_menu_requested.connect(_return_to_main_menu)
	game_over_menu.restart_requested.connect(_restart_game)

	settings_screen.back_requested.connect(_return_from_subscreen)
	settings_screen.grid_brightness_changed.connect(_set_grid_brightness)
	settings_screen.hud_scale_changed.connect(_set_hud_scale)
	credits_screen.back_requested.connect(_return_from_subscreen)


func _connect_gameplay() -> void:
	if player == null:
		push_warning("gameplay_menu_controller: Player not found")
		return
	if not player.died.is_connected(_open_game_over):
		player.died.connect(_open_game_over)


func _start_game() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	var exit_tween: Tween = main_menu.play_exit()
	_tween_camera_zoom(_gameplay_camera_zoom)
	if exit_tween != null:
		await exit_tween.finished
	_enter_playing()
	_show_only(null)
	_is_transitioning = false


func _open_pause_menu() -> void:
	_enter_paused()
	_show_only(pause_menu)


func _open_game_over() -> void:
	if _is_transitioning or _state == GameState.GAME_OVER:
		return
	_state = GameState.GAME_OVER
	if wave_manager != null and wave_manager.has_method("stop_game"):
		wave_manager.stop_game()
	if player != null and player.has_method("disable_input"):
		player.disable_input()
	get_tree().paused = true
	_show_only(game_over_menu)


func _resume_game() -> void:
	_enter_playing(false)
	_show_only(null)


func _return_to_main_menu() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	var active_menu: Control = pause_menu if _state == GameState.PAUSED else game_over_menu
	var exit_tween: Tween = active_menu.play_exit()
	_tween_camera_zoom(_menu_camera_zoom)
	if exit_tween != null:
		await exit_tween.finished
	_enter_main_menu()
	if UpgradeManager.has_method("reset"):
		UpgradeManager.reset()
	if player != null and player.has_method("reset_for_restart"):
		player.reset_for_restart()
	_show_only(main_menu)
	_is_transitioning = false


func _restart_game() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	var exit_tween: Tween = game_over_menu.play_exit()
	if exit_tween != null:
		await exit_tween.finished
	if UpgradeManager.has_method("reset"):
		UpgradeManager.reset()
	if player != null and player.has_method("reset_for_restart"):
		player.reset_for_restart()
	_enter_playing()
	_show_only(null)
	_is_transitioning = false


func _open_settings(return_screen: Control) -> void:
	_return_screen = return_screen
	_show_only(settings_screen)


func _open_credits(return_screen: Control) -> void:
	_return_screen = return_screen
	_show_only(credits_screen)


func _return_from_subscreen() -> void:
	_show_only(_return_screen)


func _quit_game() -> void:
	get_tree().quit()


func _show_only(screen: Control) -> void:
	for node in [main_menu, settings_screen, credits_screen, pause_menu, game_over_menu]:
		node.visible = node == screen
	if screen != null and screen.has_method("play_intro"):
		screen.play_intro()


func _set_grid_brightness(value: float) -> void:
	var strength := clampf(value / 100.0, 0.1, 1.5)
	if crt_screen.material is ShaderMaterial:
		var shader_material := crt_screen.material as ShaderMaterial
		shader_material.set_shader_parameter("overlay_color", Color(0.45, 0.95, 0.92, 0.04 + strength * 0.08))
		shader_material.set_shader_parameter("scanline_strength", 0.12 + strength * 0.24)


func _set_hud_scale(value: float) -> void:
	var scaled := clampf(value / 100.0, 0.75, 1.5)
	scale = Vector2.ONE * scaled


func _tween_camera_zoom(target_zoom: Vector2) -> void:
	if gameplay_camera == null:
		return
	if _camera_tween != null and _camera_tween.is_valid():
		_camera_tween.kill()

	_camera_tween = create_tween()
	_camera_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_camera_tween.set_trans(Tween.TRANS_QUAD)
	_camera_tween.set_ease(Tween.EASE_OUT)
	_camera_tween.tween_property(gameplay_camera, "zoom", target_zoom, CAMERA_TRANSITION_DURATION)


func _enter_main_menu(stop_wave: bool = true) -> void:
	_state = GameState.MAIN_MENU
	if stop_wave and wave_manager != null and wave_manager.has_method("stop_game"):
		wave_manager.stop_game()
	get_tree().paused = true
	GlobalEventBus.emit_main_menu()


func _enter_playing(start_wave: bool = true) -> void:
	_state = GameState.PLAYING
	get_tree().paused = false
	if start_wave and wave_manager != null and wave_manager.has_method("start_game"):
		wave_manager.start_game()
	GlobalEventBus.emit_play()


func _enter_paused() -> void:
	_state = GameState.PAUSED
	get_tree().paused = true
	GlobalEventBus.emit_pause()
