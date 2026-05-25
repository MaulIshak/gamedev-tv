class_name Explosion extends Node2D

@export var duration: float = 0.5
@export var hold_duration: float = 3.0
@export var fade_duration: float = 1.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var damage_area: Projectile = $DamageArea
@onready var collision_shape: CollisionShape2D = $DamageArea/CollisionShape2D

func _ready() -> void:
	var rect := sprite.get_rect()
	var max_radius := (max(rect.size.x, rect.size.y) as float) * 0.5

	var twn := create_tween()
	twn.set_trans(Tween.TRANS_CUBIC)
	twn.set_ease(Tween.EASE_OUT)
	twn.tween_method(_set_progress.bind(max_radius), 0.0, 0.9, duration)
	twn.tween_interval(hold_duration)
	twn.set_ease(Tween.EASE_IN)
	twn.tween_method(_set_glow_alpha, 1.0, 0.0, fade_duration)
	twn.finished.connect(queue_free)
	sprite.material = sprite.material.duplicate()

func _set_progress(value: float, max_radius: float) -> void:
	if sprite.material:
		sprite.material.set_shader_parameter("progress", value)
	if collision_shape.shape is CircleShape2D:
		var circle := collision_shape.shape as CircleShape2D
		circle.radius = max_radius * value

func _set_glow_alpha(alpha: float) -> void:
	if sprite.material:
		var color := sprite.material.get_shader_parameter("glow_color") as Color
		color.a = alpha
		sprite.material.set_shader_parameter("glow_color", color)
