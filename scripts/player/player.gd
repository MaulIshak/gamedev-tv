class_name Player
extends CharacterBody2D

signal died

const WHOOSH_SFX: AudioStream = preload("res://assets/audio/sfx/whoosh.wav")
const HIT_DAMAGE_SFX: AudioStream = preload("res://assets/audio/sfx/hit_damage.wav")

@export_group("Movement Settings")
@export var walk_speed: float = 200.0
@export var acceleration: float = 2500.0
@export var friction: float = 2500.0

@export_group("Dash Settings")
@export var dash_speed: float = 500.0
@export var dash_duration: float = 0.07
@export var dash_cooldown: float = 0.20
@export var dash_trail_interval: float = 0.02
@export var dash_trail_lifetime: float = 0.12
@export var dash_bar_smoothing_speed: float = 8.0

@export_group("Visual Effects")
@export var damage_flash_duration: float = 0.10
@export var immune_blink_interval: float = 0.08
@export var trail_modulate: Color = Color(1.0, 1.0, 1.0, 0.45)

@export_group("Footstep SFX")
@export var footstep_interval: float = 0.28
@export var footstep_min_speed: float = 10.0
@export var footstep_pitch_variation: float = 0.04

var input_direction: Vector2 = Vector2.ZERO
var last_move_direction: Vector2 = Vector2.DOWN
var dash_direction: Vector2 = Vector2.ZERO
var is_dashing: bool = false
var _dash_time_left: float = 0.0
var _dash_cooldown_left: float = 0.0
var _dash_trail_time_left: float = 0.0
var _footstep_time_left: float = 0.0

var is_input_disabled: bool = false

var immune_duration: float = 0.5
var _immune_time_left: float = 0.0
var _immune_blink_time_left: float = 0.0
var is_immune: bool = false
@export_group("Player Stats")
var health: int = 5
var max_health: int = 5


const IDLE = "IdleState"
const WALK = "WalkState"

var _base_walk_speed: float = 0.0
var _base_dash_cooldown: float = 0.0
var _base_immune_duration: float = 0.0
var _dash_bar_display_value: float = 1.0

@onready var tower_detector: Area2D = $TowerDetector
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var footstep_sfx: AudioStreamPlayer2D = $FootstepSFX
var _damage_flash_tween: Tween

@onready var dash_bar: ProgressBar = $Control/ProgressBar

func _ready() -> void:
	enable_input()
	sprite.visible = true
	sprite.modulate = Color.WHITE
	if dash_bar != null:
		dash_bar.min_value = 0.0
		dash_bar.max_value = 1.0
		_dash_bar_display_value = get_dash_cooldown_progress()
		dash_bar.value = _dash_bar_display_value

	_base_walk_speed = walk_speed
	_base_dash_cooldown = dash_cooldown
	_base_immune_duration = immune_duration

	_apply_upgrade_stats()
	UpgradeManager.upgraded.connect(_on_upgrade_applied)
	UpgradeManager.instant_effect_applied.connect(_on_instant_effect)
	_update_dash_bar(0.0)
	# notify HUD of initial health
	GlobalEventBus.set_hearts(health, max_health)

func _process(_delta: float) -> void:
	if is_immune:
		_immune_time_left -= _delta
		_immune_blink_time_left -= _delta
		if _immune_blink_time_left <= 0.0:
			sprite.visible = not sprite.visible
			_immune_blink_time_left = immune_blink_interval
		if _immune_time_left <= 0.0:
			is_immune = false
			sprite.visible = true

	if input_direction.x != 0:
		sprite.flip_h = input_direction.x < 0

func _physics_process(_delta: float) -> void:
	if _dash_cooldown_left > 0.0:
		_dash_cooldown_left = max(_dash_cooldown_left - _delta, 0.0)

	if is_input_disabled:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_dash_bar(_delta)
		return

	input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
	if input_direction != Vector2.ZERO:
		last_move_direction = input_direction

	if Input.is_action_just_pressed("dash"):
		_start_dash()

	if is_dashing:
		_dash_time_left -= _delta
		_dash_trail_time_left -= _delta
		if _dash_trail_time_left <= 0.0:
			_spawn_dash_trail()
			_dash_trail_time_left = dash_trail_interval
		velocity = dash_direction * dash_speed
		if _dash_time_left <= 0.0:
			is_dashing = false
	else:
		var target_velocity := input_direction * walk_speed
		if target_velocity == Vector2.ZERO:
			velocity = velocity.move_toward(Vector2.ZERO, friction * _delta)
		else:
			velocity = velocity.move_toward(target_velocity, acceleration * _delta)

	_update_footstep_sfx(_delta)

	move_and_slide()
	_update_dash_bar(_delta)


func _update_dash_bar(delta: float) -> void:
	if dash_bar == null:
		return

	var dash_progress_target := get_dash_cooldown_progress()
	if is_dashing:
		dash_progress_target = 0.0

	if delta <= 0.0:
		_dash_bar_display_value = dash_progress_target
	else:
		_dash_bar_display_value = move_toward(
			_dash_bar_display_value,
			dash_progress_target,
			dash_bar_smoothing_speed * delta
		)

	dash_bar.value = _dash_bar_display_value
	dash_bar.modulate = Color(0.55, 1.0, 0.55, 1.0) if _dash_bar_display_value >= 0.999 else Color(1.0, 0.82, 0.35, 1.0)

func disable_input():
	is_input_disabled = true
	is_dashing = false
	_dash_time_left = 0.0
	_footstep_time_left = 0.0
	velocity = Vector2.ZERO
	sprite.visible = true

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
	_dash_trail_time_left = 0.0
	if SfxManager != null:
		SfxManager.play_sfx_once(WHOOSH_SFX, &"SFX", 0.0, false, true)
	_spawn_dash_trail()


func _spawn_dash_trail() -> void:
	if sprite.sprite_frames == null:
		return

	var frame_texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if frame_texture == null:
		return

	var trail := Sprite2D.new()
	trail.texture = frame_texture
	trail.centered = sprite.centered
	trail.offset = sprite.offset
	trail.flip_h = sprite.flip_h
	trail.flip_v = sprite.flip_v
	trail.global_transform = sprite.global_transform
	trail.modulate = trail_modulate
	trail.z_index = sprite.z_index

	var scene_parent := get_tree().current_scene if get_tree().current_scene != null else get_parent()
	if scene_parent == null:
		return

	scene_parent.add_child(trail)

	var trail_tween := create_tween()
	trail_tween.tween_property(trail, "modulate:a", 0.0, dash_trail_lifetime)
	trail_tween.finished.connect(trail.queue_free)


func _play_damage_flash() -> void:
	if _damage_flash_tween != null:
		_damage_flash_tween.kill()

	sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
	_damage_flash_tween = create_tween()
	_damage_flash_tween.tween_property(sprite, "modulate", Color.WHITE, damage_flash_duration)
	if SfxManager != null:
		SfxManager.play_sfx_once(HIT_DAMAGE_SFX, &"SFX", 0.0, false, true)

	var camera := get_viewport().get_camera_2d()
	if camera != null and camera.has_method("shake"):
		camera.call("shake", 1.0, damage_flash_duration)


func _update_footstep_sfx(delta: float) -> void:
	if is_input_disabled or is_dashing or footstep_sfx == null or footstep_interval <= 0.0:
		_footstep_time_left = 0.0
		return

	if input_direction == Vector2.ZERO or velocity.length() < footstep_min_speed:
		_footstep_time_left = 0.0
		return

	_footstep_time_left -= delta
	if _footstep_time_left > 0.0:
		return

	footstep_sfx.pitch_scale = 1.0 + randf_range(-footstep_pitch_variation, footstep_pitch_variation)
	footstep_sfx.play()
	_footstep_time_left = footstep_interval


func get_dash_cooldown_progress() -> float:
	if dash_cooldown <= 0.0:
		return 1.0

	return clampf(1.0 - (_dash_cooldown_left / dash_cooldown), 0.0, 1.0)


func take_damage(amount: int) -> void:
	if health <= 0:
		return

	if is_immune:
		print("Masih immune bang")
		return

	health -= amount
	is_immune = true
	_immune_time_left = immune_duration
	_immune_blink_time_left = immune_blink_interval
	sprite.visible = true
	_play_damage_flash()

	print("Sakit woi! Remaining health: %d" % health)

	if health <= 0:
		health = 0
		die()
	# update HUD
	GlobalEventBus.set_hearts(health, max_health)

func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	GlobalEventBus.set_hearts(health, max_health)

func _apply_upgrade_stats() -> void:
	walk_speed = _base_walk_speed + UpgradeManager.get_stat_add("walk_speed")
	dash_cooldown = _base_dash_cooldown + UpgradeManager.get_stat_add("dash_cooldown")
	immune_duration = _base_immune_duration
	max_health = int(5.0 + UpgradeManager.get_stat_add("max_hp"))
	GlobalEventBus.set_hearts(health, max_health)

func _on_upgrade_applied(_id: String, _new_level: int) -> void:
	_apply_upgrade_stats()

func _on_instant_effect(id: String, value: float) -> void:
	if id == "heal":
		heal(int(value))

func die() -> void:
	print("Mati woi")
	disable_input()
	died.emit()


func reset_for_restart() -> void:
	_apply_upgrade_stats()
	health = max_health
	GlobalEventBus.set_hearts(health, max_health)
	is_immune = false
	_immune_time_left = 0.0
	_immune_blink_time_left = 0.0
	is_dashing = false
	_dash_time_left = 0.0
	_dash_cooldown_left = 0.0
	_dash_trail_time_left = 0.0
	dash_direction = Vector2.ZERO
	velocity = Vector2.ZERO
	sprite.visible = true
	sprite.modulate = Color.WHITE
	enable_input()
