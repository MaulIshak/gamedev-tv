class_name WalkState
extends PlayerState

func enter() -> void:
	pass

func process(_delta: float) -> void:
	if player.is_input_disabled:
		finished.emit(Player.IDLE)
		return

	if player.input_direction == Vector2.ZERO:
		finished.emit(Player.IDLE)

func physics_process(_delta: float) -> void:
	pass

func exit() -> void:
	pass
