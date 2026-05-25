class_name EnemyExplosionParticles
extends Node2D

@export var burst_amount: int = 28
@export var burst_lifetime: float = 0.35
@export var burst_speed_min: float = 90.0
@export var burst_speed_max: float = 190.0
@export var burst_gravity: float = 180.0

@onready var particles: GPUParticles2D = $GPUParticles2D


func _ready() -> void:
    particles.amount = burst_amount
    particles.lifetime = burst_lifetime
    particles.one_shot = true
    particles.explosiveness = 1.0
    particles.local_coords = false
    particles.emitting = false
    particles.texture = _create_particle_texture()
    particles.process_material = _create_process_material()
    particles.emitting = true

    await get_tree().create_timer(burst_lifetime + 0.35).timeout
    queue_free()


func _create_process_material() -> ParticleProcessMaterial:
    var process_material := ParticleProcessMaterial.new()
    process_material.direction = Vector3(0.0, -1.0, 0.0)
    process_material.spread = 180.0
    process_material.initial_velocity_min = burst_speed_min
    process_material.initial_velocity_max = burst_speed_max
    process_material.gravity = Vector3(0.0, burst_gravity, 0.0)
    process_material.angular_velocity_min = -360.0
    process_material.angular_velocity_max = 360.0
    process_material.scale_min = 0.35
    process_material.scale_max = 1.0
    process_material.scale_curve = _create_scale_curve_texture()
    process_material.color = Color(1.0, 1.0, 1.0, 1.0)
    return process_material


func _create_particle_texture() -> Texture2D:
    var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
    var center := Vector2(7.5, 7.5)
    var max_distance := 7.5

    for y in range(16):
        for x in range(16):
            var pixel_position := Vector2(x, y)
            var distance := pixel_position.distance_to(center)
            var alpha := clampf(1.0 - distance / max_distance, 0.0, 1.0)
            image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha * alpha))

    return ImageTexture.create_from_image(image)


func _create_scale_curve_texture() -> CurveTexture:
    var curve := Curve.new()
    curve.add_point(Vector2(0.0, 1.0))
    curve.add_point(Vector2(0.35, 1.15))
    curve.add_point(Vector2(1.0, 0.0))

    var curve_texture := CurveTexture.new()
    curve_texture.curve = curve
    return curve_texture