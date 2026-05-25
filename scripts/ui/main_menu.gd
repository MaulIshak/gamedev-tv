class_name MainMenu
extends Control

const SequentialMenuAnimation = preload("res://scripts/ui/sequential_menu_animation.gd")

signal start_requested
signal settings_requested
signal credits_requested
signal quit_requested

@onready var _buttons: Array[Control] = [
	$VBoxContainer/StartGame,
	$VBoxContainer/Settings,
	$VBoxContainer/Credits,
	$VBoxContainer/Quit,
]


func _ready() -> void:
	$VBoxContainer/StartGame.pressed.connect(func() -> void: start_requested.emit())
	$VBoxContainer/Settings.pressed.connect(func() -> void: settings_requested.emit())
	$VBoxContainer/Credits.pressed.connect(func() -> void: credits_requested.emit())
	$VBoxContainer/Quit.pressed.connect(func() -> void:
		quit_requested.emit()
	)

	$VBoxContainer/StartGame.pressed.connect(func() -> void:
		start_requested.emit()
		GlobalEventBus.emit_play()
	)


func play_intro() -> void:
	SequentialMenuAnimation.play(self, _buttons)
