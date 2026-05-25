extends Node2D

@onready var crt_screen: ColorRect = $CRTScreen
@onready var main_menu = $MainMenu
@onready var settings_screen = $SettingsScreen
@onready var credits_screen = $CreditsScreen
@onready var pause_menu = $PauseMenu

var _return_screen: Control
var _game_started := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_menus()
	_show_only(main_menu)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu") and _game_started:
		if pause_menu.visible:
			_resume_game()
		else:
			_open_pause_menu()


func _connect_menus() -> void:
	main_menu.start_requested.connect(_start_game)
	main_menu.settings_requested.connect(_open_settings.bind(main_menu))
	main_menu.credits_requested.connect(_open_credits.bind(main_menu))
	main_menu.quit_requested.connect(_quit_game)

	pause_menu.resume_requested.connect(_resume_game)
	pause_menu.restart_requested.connect(_restart_level)
	pause_menu.settings_requested.connect(_open_settings.bind(pause_menu))
	pause_menu.main_menu_requested.connect(_return_to_main_menu)

	settings_screen.back_requested.connect(_return_from_subscreen)
	settings_screen.grid_brightness_changed.connect(_set_grid_brightness)
	settings_screen.hud_scale_changed.connect(_set_hud_scale)
	credits_screen.back_requested.connect(_return_from_subscreen)


func _start_game() -> void:
	_game_started = true
	get_tree().paused = false
	_show_only(null)


func _open_pause_menu() -> void:
	get_tree().paused = true
	_show_only(pause_menu)
	GlobalEventBus.emit_pause()


func _resume_game() -> void:
	get_tree().paused = false
	_show_only(null)
	GlobalEventBus.emit_resume()


func _return_to_main_menu() -> void:
	_game_started = false
	get_tree().paused = false
	_show_only(main_menu)


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


func _restart_level() -> void:
	get_tree().paused = false
	GlobalEventBus.emit_restart()
	get_tree().reload_current_scene()


func _show_only(screen: Control) -> void:
	for node in [main_menu, settings_screen, credits_screen, pause_menu]:
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
