extends Camera2D


@export var shake_decay: float = 10.0
@export var shake_max_offset: float = 5.0
@export var shake_max_roll: float = 0.02

var _shake_strength: float = 0.0
var _shake_time_left: float = 0.0
var _base_offset: Vector2 = Vector2.ZERO
var _base_rotation: float = 0.0

func _ready() -> void:
	make_current()
	_base_offset = offset
	_base_rotation = rotation


func _process(delta: float) -> void:
	if _shake_time_left > 0.0:
		_shake_time_left = max(_shake_time_left - delta, 0.0)
		_shake_strength = lerpf(_shake_strength, 0.0, shake_decay * delta)
		var shake_amount: float = min(_shake_strength, 1.0)
		offset = _base_offset + Vector2(
			randf_range(-shake_max_offset, shake_max_offset) * shake_amount,
			randf_range(-shake_max_offset, shake_max_offset) * shake_amount
		)
		rotation = _base_rotation + randf_range(-shake_max_roll, shake_max_roll) * shake_amount
		if _shake_strength <= 0.01:
			_stop_shake()
	else:
		_stop_shake()


func shake(strength: float = 1.0, duration: float = 0.15) -> void:
	var multiplier := 1.0
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var mode = int(config.get_value("gameplay", "screen_shake", 1))
		if mode == 0:
			multiplier = 0.0
		elif mode == 1:
			multiplier = 0.4
		else:
			multiplier = 1.0

	if multiplier > 0.0:
		_shake_strength = max(_shake_strength, strength * multiplier)
		_shake_time_left = max(_shake_time_left, duration)


func _stop_shake() -> void:
	offset = _base_offset
	rotation = _base_rotation
	if _shake_time_left <= 0.0:
		_shake_strength = 0.0
