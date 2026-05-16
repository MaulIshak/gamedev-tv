# Base class for all states in the state machine
class_name State
extends Node

# Emitted when the state is finished and wants to change to another state
@warning_ignore("unused_signal")
signal finished(new_state: StringName)

func enter() -> void:
	pass

func process(_delta: float) -> void:
	pass

func physics_process(_delta: float) -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass
	
func exit() -> void:
	pass
