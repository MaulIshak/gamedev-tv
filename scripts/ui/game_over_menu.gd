class_name GameOverMenu
extends Control

const MenuAnimation = preload("res://scripts/ui/sequential_menu_animation.gd")

signal main_menu_requested
signal restart_requested

@onready var _buttons: Array[Control] = [
	$Title,
	$VBoxContainer/MainMenu,
	$VBoxContainer/Restart,
]

var _base_position: Vector2


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_base_position = position

	$VBoxContainer/MainMenu.pressed.connect(func() -> void: main_menu_requested.emit())
	$VBoxContainer/Restart.pressed.connect(func() -> void: restart_requested.emit())


func play_intro() -> void:
	position = _base_position
	modulate.a = 1.0
	MenuAnimation.play(self, _buttons)


func play_exit() -> Tween:
	return MenuAnimation.play_exit(self, _buttons)
