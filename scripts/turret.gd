class_name Turret
extends Node2D

@export var popup_time: float = 0.32
@export var start_hidden: bool = true

@onready var turret_body: Node2D = $Mask/TurretBody
@onready var floor_sprite: Sprite2D = $Mask/TurretBody/Floor
@onready var node_sprite: Sprite2D = $Mask/TurretBody/Node
@onready var base_sprite: Sprite2D = $Mask/Base
@onready var area: Area2D = $Area2D

var clip_size: Vector2 = Vector2(16.0, 28.0)
var hidden_floor_depth: float = 10.0

var _shown_body_position: Vector2
var _tween: Tween
var _body_sprites: Array[Sprite2D] = []
var _source_regions: Dictionary = {}
var _source_positions: Dictionary = {}

var is_connected_tower: bool = false


func _ready() -> void:
	_body_sprites = [floor_sprite, node_sprite]
	_shown_body_position = turret_body.position
	_store_source_sprite_state()
	if start_hidden:
		snap_hidden()
	else:
		snap_shown()


func show_turret() -> void:
	visible = true
	_animate_body_to(_shown_body_position)


func hide_turret() -> void:
	visible = true
	_animate_body_to(_get_hidden_body_position())


func snap_shown() -> void:
	visible = true
	_kill_tween()
	_set_body_position(_shown_body_position)


func snap_hidden() -> void:
	visible = true
	_kill_tween()
	_set_body_position(_get_hidden_body_position())


func on_connection_expired() -> void:
	pass


func _store_source_sprite_state() -> void:
	for sprite in _body_sprites:
		_source_regions[sprite] = sprite.region_rect
		_source_positions[sprite] = sprite.position


func _animate_body_to(target_position: Vector2) -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_body_position, turret_body.position, target_position, popup_time)


func _set_body_position(body_position: Vector2) -> void:
	turret_body.position = body_position


func _get_hidden_body_position() -> Vector2:
	var floor_region := _source_regions.get(floor_sprite, floor_sprite.region_rect) as Rect2
	var floor_position := _source_positions.get(floor_sprite, floor_sprite.position) as Vector2
	var floor_bottom_at_zero := floor_position.y + floor_region.size.y

	var base_bottom := _get_sprite_bottom(base_sprite)
	var hidden_y := base_bottom + hidden_floor_depth - floor_bottom_at_zero

	return Vector2(_shown_body_position.x, hidden_y)


func _get_sprite_bottom(sprite: Sprite2D) -> float:
	var size := _get_sprite_size(sprite)
	if sprite.centered:
		return sprite.position.y + sprite.offset.y + size.y * 0.5
	return sprite.position.y + sprite.offset.y + size.y


func _get_sprite_size(sprite: Sprite2D) -> Vector2:
	if sprite.region_enabled:
		return sprite.region_rect.size
	if sprite.texture != null:
		return sprite.texture.get_size()
	return Vector2.ZERO


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
