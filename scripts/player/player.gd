class_name Player
extends CharacterBody2D

@export_group("Movement Settings")
@export var walk_speed: float = 200.0
@export var acceleration: float = 2500.0
@export var friction: float = 2500.0

@export_group("Dash Settings")
@export var dash_speed: float = 500.0
@export var dash_duration: float = 0.07
@export var dash_cooldown: float = 0.20

var input_direction: Vector2 = Vector2.ZERO
var last_move_direction: Vector2 = Vector2.DOWN
var dash_direction: Vector2 = Vector2.ZERO
var is_dashing: bool = false
var _dash_time_left: float = 0.0
var _dash_cooldown_left: float = 0.0

var is_input_disabled: bool = false


const IDLE = "IdleState"
const WALK = "WalkState"


func _ready() -> void:
    enable_input()

func _physics_process(_delta: float) -> void:
    if _dash_cooldown_left > 0.0:
        _dash_cooldown_left = max(_dash_cooldown_left - _delta, 0.0)

    if is_input_disabled:
        velocity = Vector2.ZERO
        move_and_slide()
        return

    input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
    if input_direction != Vector2.ZERO:
        last_move_direction = input_direction

    if Input.is_action_just_pressed("dash"):
        _start_dash()

    if is_dashing:
        _dash_time_left -= _delta
        velocity = dash_direction * dash_speed
        if _dash_time_left <= 0.0:
            is_dashing = false
    else:
        var target_velocity := input_direction * walk_speed
        if target_velocity == Vector2.ZERO:
            velocity = velocity.move_toward(Vector2.ZERO, friction * _delta)
        else:
            velocity = velocity.move_toward(target_velocity, acceleration * _delta)

    move_and_slide()

func disable_input():
    is_input_disabled = true
    is_dashing = false
    _dash_time_left = 0.0
    velocity = Vector2.ZERO

func enable_input():
    is_input_disabled = false


func _start_dash() -> void:
    if is_dashing or _dash_cooldown_left > 0.0:
        return

    var direction := input_direction if input_direction != Vector2.ZERO else last_move_direction
    if direction == Vector2.ZERO:
        return

    dash_direction = direction.normalized()
    is_dashing = true
    _dash_time_left = dash_duration
    _dash_cooldown_left = dash_cooldown


func get_dash_cooldown_progress() -> float:
    if dash_cooldown <= 0.0:
        return 1.0

    return clampf(1.0 - (_dash_cooldown_left / dash_cooldown), 0.0, 1.0)
