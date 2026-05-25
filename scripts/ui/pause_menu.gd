class_name PauseMenu
extends Control

const SequentialMenuAnimation = preload("res://scripts/ui/sequential_menu_animation.gd")

signal resume_requested
signal settings_requested
signal main_menu_requested

@onready var _buttons: Array[Control] = [
	$VBoxContainer/Resume,
	$VBoxContainer/Settings,
	$VBoxContainer/MainMenu,
]

var _base_position: Vector2


func _ready() -> void:
	_base_position = position

	$VBoxContainer/Resume.pressed.connect(func() -> void: resume_requested.emit())
	$VBoxContainer/Settings.pressed.connect(func() -> void: settings_requested.emit())
	$VBoxContainer/MainMenu.pressed.connect(func() -> void: main_menu_requested.emit())

func play_intro() -> void:
	position = _base_position
	modulate.a = 1.0
	SequentialMenuAnimation.play(self, _buttons)


func play_exit() -> Tween:
	return SequentialMenuAnimation.play_exit(self, _buttons)
