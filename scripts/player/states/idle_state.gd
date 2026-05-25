class_name IdleState
extends PlayerState

func enter() -> void:
    player.sprite.play("idle")

func process(_delta: float) -> void:
    if player.is_input_disabled:
        return

    if player.input_direction != Vector2.ZERO:
        finished.emit(Player.WALK)


func physics_process(_delta: float) -> void:
    pass
