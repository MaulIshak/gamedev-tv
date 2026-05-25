class_name MainMenu
extends Control

const SequentialMenuAnimation = preload("res://scripts/ui/sequential_menu_animation.gd")

signal start_requested
signal settings_requested
signal credits_requested
signal quit_requested

@onready var _buttons: Array[Control] = [
	$Control,
	$VBoxContainer/StartGame,
	$VBoxContainer/Settings,
	$VBoxContainer/Credits,
	$VBoxContainer/Quit,
]

var _base_position: Vector2


func _ready() -> void:
	_base_position = position

	$VBoxContainer/StartGame.pressed.connect(func() -> void: start_requested.emit())
	$VBoxContainer/Settings.pressed.connect(func() -> void: settings_requested.emit())
	$VBoxContainer/Credits.pressed.connect(func() -> void: credits_requested.emit())
	$VBoxContainer/Quit.pressed.connect(func() -> void:
		quit_requested.emit()
		GlobalEventBus.emit_quit()
	)


func play_intro() -> void:
	position = _base_position
	modulate.a = 1.0
	SequentialMenuAnimation.play(self, _buttons)


func play_exit() -> Tween:
	return SequentialMenuAnimation.play_exit(self, _buttons)
