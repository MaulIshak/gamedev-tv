extends Node 

signal play_requested
signal pause_requested
signal resume_requested
signal restart_requested
signal main_menu_requested
signal settings_requested
signal settings_applied
signal quit_requested
signal hearts_changed(current: int, max: int)

func emit_play() -> void:
	emit_signal("play_requested")

func emit_pause() -> void:
	emit_signal("pause_requested")

func emit_resume() -> void:
	emit_signal("resume_requested")

func emit_restart() -> void:
	emit_signal("restart_requested")

func emit_main_menu() -> void:
	emit_signal("main_menu_requested")

func emit_settings() -> void:
	emit_signal("settings_requested")

func emit_settings_applied() -> void:
	emit_signal("settings_applied")

func emit_quit() -> void:
	emit_signal("quit_requested")

func set_hearts(current: int, max: int) -> void:
	emit_signal("hearts_changed", current, max)
