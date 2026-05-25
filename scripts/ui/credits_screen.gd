class_name CreditsScreen
extends Control

signal back_requested

const INTRO_OFFSET := Vector2(0.0, -46.0)
const INTRO_DURATION := 0.22

var _base_position: Vector2
var _intro_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_base_position = position
	$Panel/BackButton.pressed.connect(func() -> void: back_requested.emit())


func play_intro() -> void:
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()

	position = _base_position + INTRO_OFFSET
	modulate.a = 0.0
	_intro_tween = create_tween()
	_intro_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_intro_tween.set_parallel(true)
	_intro_tween.tween_property(self, "position", _base_position, INTRO_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_intro_tween.tween_property(self, "modulate:a", 1.0, INTRO_DURATION * 0.75)
