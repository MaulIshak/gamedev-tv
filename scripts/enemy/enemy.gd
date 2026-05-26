extends CharacterBody2D

const HIT_DAMAGE_SFX: AudioStream = preload("res://assets/audio/sfx/hit_damage.wav")
const ENEMY_EXPLOSION_PARTICLES_SCENE: PackedScene = preload("res://scenes/enemy_explosion_particles.tscn")

@export_group("Navigation Settings")
## The movement speed of the entity
@export var movement_speed: float = 8000.0
## The target node to move to
@export var movement_target: Node2D

## Reference to the navigation agent node.
## A NavigationAgent2D node must be added to your scene and referenced here in order-
## to communicate with the navigation server.
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
## Reference to the recalculation timer.
@onready var recalc_timer: Timer = $RecalcTimer

var on_nav_link: bool = false
var nav_link_end_position: Vector2

@export_group("Enemy Stats")
var health: int = 3
var damage: int = 1
var attack_cooldown: float = .5
@export var enemy_stats: EnemyStats
@onready var attack_timer: Timer = $AttackTimer

var player_in_range: Player = null
@onready var hitbox_area: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _base_movement_speed: float = 0.0
var _is_slowed: bool = false
var _slow_timer: float = 0.0
var _active_slow_amount: float = 1.0
var _damage_immunity_timer: float = 0.0
var _damage_immunity_duration: float = 0.5
var _damage_flash_tween: Tween
var _spawn_tween: Tween
var score_value: int = 10

func _ready():
	# Connect signals
	recalc_timer.timeout.connect(_on_recalc_timer_timeout)
	navigation_agent.link_reached.connect(_on_navigation_link_reached)
	navigation_agent.waypoint_reached.connect(_on_waypoint_reached)
	navigation_agent.velocity_computed.connect(_on_velocity_computed)

	# These values need to be adjusted according to the actor's speed, -
	# the navigation layout, and the actor's collision shape.
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0

	# On the first frame the NavigationServer map has not-
	# yet been synchronized; region data and any path query will return empty.
	# Wait for the NavigationServer synchronization by awaiting one frame in the script.
	# Make sure to not await during _ready.
	call_deferred("actor_setup")

	# hitbox_area.body_entered.connect(_on_hitbox_body_entered)
	# hitbox_area.body_exited.connect(_on_hitbox_body_exited)
	attack_timer.timeout.connect(_on_attack_timer_timeout)

	_apply_enemy_stats()

	_damage_immunity_duration = 0.5 + UpgradeManager.get_stat_add("enemy_immunity")

	sprite.flip_h = false
	sprite.play("default")
	_play_spawn_animation()

func _apply_enemy_stats() -> void:
	var stats: EnemyStats = enemy_stats
	if stats == null:
		stats = EnemyStats.new()

	# Setup stats from the assigned resource, falling back to the resource defaults.
	health = stats.health
	damage = stats.damage
	score_value = stats.score_value
	if stats.sprite_frames != null:
		sprite.sprite_frames = stats.sprite_frames

	sprite.scale = Vector2.ZERO

	if hitbox_area.shape is CircleShape2D:
		(hitbox_area.shape as CircleShape2D).radius = stats.hitbox_radius

	attack_timer.wait_time = stats.attack_cooldown

	_base_movement_speed = movement_speed
	movement_speed = _base_movement_speed * stats.movement_speed_multiplier

func _process(delta: float) -> void:
	if _damage_immunity_timer > 0.0:
		_damage_immunity_timer -= delta

	if _is_slowed:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_is_slowed = false
			movement_speed = _base_movement_speed


func _physics_process(delta):
	# Returns if we've reached the end of the path.
	if navigation_agent.is_navigation_finished():
		return

	# Get the next path point from the navigation agent.
	var current_agent_position: Vector2 = global_position
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()

	# Calculate the velocity to move towards the next path point.
	var new_velocity = current_agent_position.direction_to(next_path_position) * movement_speed * delta
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)

## Setup the navigation agent.
func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame
	set_target_position(movement_target.position)

## Set the target position of the navigation agent.
func set_target_position(target_position: Vector2 = Vector2.ZERO) -> void:
	navigation_agent.target_position = target_position

## Called when the recalculation timer times out.
func _on_recalc_timer_timeout() -> void:
	if not on_nav_link:
		set_target_position(movement_target.position)

## Called when a navigation link has been reached.
func _on_navigation_link_reached(details: Dictionary) -> void:
	on_nav_link = true # Temporarily disable recalculation to prevent jittering.
	nav_link_end_position = details.link_exit_position

## Called when a waypoint has been reached.
func _on_waypoint_reached(details: Dictionary) -> void:
	# This next line checks the distance to the waypoint with a threshhold.
	# If the distance is less than 5.0, then the waypoint has been reached.
	# This check produces unexpected results when comparing vectors directly.
	if details.position.distance_to(nav_link_end_position) < 5.0:
		on_nav_link = false

## Called when the navigation agent reports a new velocity.
func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity

	if absf(safe_velocity.x) > 0.01:
		sprite.flip_h = safe_velocity.x < 0.0

	move_and_slide()


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is Player:
		print("Player entered hitbox")
		player_in_range = body
		_deal_damage()
		attack_timer.start()

func _on_hitbox_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
		attack_timer.stop()

func _on_attack_timer_timeout() -> void:
	_deal_damage()

func _deal_damage() -> void:
	if is_instance_valid(player_in_range):
			player_in_range.take_damage(damage)


func _on_hurt_box_area_entered(area: Area2D) -> void:
	if _damage_immunity_timer > 0.0:
		return

	var projectile := area as Projectile
	print(area, "Taking damage...", projectile.damage)
	if projectile == null:
		return
	if projectile.damage <= 0:
		return

	health -= projectile.damage
	_play_damage_feedback()
	_damage_immunity_timer = _damage_immunity_duration
	_is_slowed = true
	_slow_timer = projectile.slow_duration
	_active_slow_amount = projectile.slow_amount
	movement_speed = _base_movement_speed * _active_slow_amount

	if health <= 0:
		_spawn_death_particles()
		queue_free()
		ScoreManager.add_score(score_value)


func _play_damage_feedback() -> void:
	if _damage_flash_tween != null:
		_damage_flash_tween.kill()

	sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
	_damage_flash_tween = create_tween()
	_damage_flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

	if SfxManager != null:
		var sfx_player := SfxManager.play_sfx(HIT_DAMAGE_SFX, &"SFX", 0.0, false, false)
		if is_instance_valid(sfx_player):
			sfx_player.pitch_scale = 0.88

	var camera := get_viewport().get_camera_2d()
	if camera != null and camera.has_method("shake"):
		camera.call("shake", 0.65, 0.08)


func _play_spawn_animation() -> void:
	if _spawn_tween != null:
		_spawn_tween.kill()

	sprite.scale = Vector2.ZERO
	_spawn_tween = create_tween()
	_spawn_tween.set_trans(Tween.TRANS_BACK)
	_spawn_tween.set_ease(Tween.EASE_OUT)
	var stats: EnemyStats = enemy_stats
	if stats == null:
		stats = EnemyStats.new()
	_spawn_tween.tween_property(sprite, "scale", stats.sprite_scale, 0.18)


func _spawn_death_particles() -> void:
	if ENEMY_EXPLOSION_PARTICLES_SCENE == null:
		return

	var explosion_particles := ENEMY_EXPLOSION_PARTICLES_SCENE.instantiate() as Node2D
	if explosion_particles == null:
		return

	explosion_particles.global_position = global_position

	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_tree().root

	scene_root.add_child(explosion_particles)
