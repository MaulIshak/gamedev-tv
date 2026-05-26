extends Node

var score: int = 0

signal on_score_changed(new_score: int)

func add_score(amount: int) -> void:
    score += amount
    emit_signal("on_score_changed", score)
    print("Score: %d" % score)

func reset_score() -> void:
    score = 0