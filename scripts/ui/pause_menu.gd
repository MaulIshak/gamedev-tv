class_name PauseMenu
extends Control

const SequentialMenuAnimation = preload("res://scripts/ui/sequential_menu_animation.gd")

signal resume_requested
signal settings_requested
signal main_menu_requested
signal restart_requested

@onready var _buttons: Array[Control] = [
	$VBoxContainer/Resume,
	$VBoxContainer/Restart,
	$VBoxContainer/Settings,
	$VBoxContainer/MainMenu,
]


func _ready() -> void:
	$VBoxContainer/Resume.pressed.connect(func() -> void: resume_requested.emit())
	$VBoxContainer/Restart.pressed.connect(func() -> void: restart_requested.emit())
	$VBoxContainer/Settings.pressed.connect(func() -> void: settings_requested.emit())
	$VBoxContainer/MainMenu.pressed.connect(func() -> void: main_menu_requested.emit())

func play_intro() -> void:
	SequentialMenuAnimation.play(self, _buttons)
