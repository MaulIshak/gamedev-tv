extends Node2D

@export var turret_scene: PackedScene = preload("res://scenes/turret.tscn")
@export var tile_size: float = 16.0
@export var turret_count: int = 4

@onready var top_wall_layer: TileMapLayer = $TopWall
@onready var inner_wall_layer: TileMapLayer = $InnerWall
@onready var floor_layer: TileMapLayer = $Floor
@onready var turret_root: Node2D = $turrets/turret_spawn
@onready var preview_turret: Node2D = $PreviewTurret
@onready var randomize_button: Button = $UI/PanelContainer/VBoxContainer/RandomizeButton
@onready var hide_button: Button = $UI/PanelContainer/VBoxContainer/HideButton
@onready var show_button: Button = $UI/PanelContainer/VBoxContainer/ShowButton

const FLOOR_SOURCE_ID := 0
const TOP_WALL_VARIANTS: Array[Vector2i] = [
	Vector2i(1, 1),
	Vector2i(3, 1),
	Vector2i(5, 1),
	Vector2i(7, 1),
	Vector2i(9, 1),
	Vector2i(11, 1),
	Vector2i(13, 1),
	Vector2i(15, 1)
]
const INNER_WALL_VARIANTS: Array[Vector2i] = [
	Vector2i(1, 3),
	Vector2i(1, 4),
	Vector2i(1, 5),
	Vector2i(3, 4),
	Vector2i(5, 4),
	Vector2i(7, 4),
	Vector2i(10, 4)
]
const FLOOR_VARIANTS: Array[Vector2i] = [
	Vector2i(1, 7),
	Vector2i(2, 7),
	Vector2i(4, 7),
	Vector2i(6, 7),
	Vector2i(8, 7),
	Vector2i(9, 7),
	Vector2i(11, 7),
	Vector2i(13, 7),
	Vector2i(15, 7),
	Vector2i(17, 7),
	Vector2i(18, 7),
	Vector2i(1, 8),
	Vector2i(2, 8),
	Vector2i(8, 8),
	Vector2i(15, 8)
]

var _spawn_cells: Array[Vector2i] = []
var _turrets: Array[Turret] = []


func _ready() -> void:
	randomize()
	if not Engine.is_editor_hint() and is_instance_valid(preview_turret):
		preview_turret.queue_free()

	randomize_button.pressed.connect(_on_randomize_button_pressed)
	hide_button.pressed.connect(_on_hide_button_pressed)
	show_button.pressed.connect(_on_show_button_pressed)

	_build_test_floor()
	randomize_turrets()


func _build_test_floor() -> void:
	top_wall_layer.clear()
	inner_wall_layer.clear()
	floor_layer.clear()
	_spawn_cells.clear()

	for x in range(-16, 17):
		_place_cycled_tile(top_wall_layer, Vector2i(x, 0), TOP_WALL_VARIANTS, x)
		_place_cycled_tile(inner_wall_layer, Vector2i(x, 1), INNER_WALL_VARIANTS, x)

	for y in range(2, 11):
		for x in range(-16, 17):
			_place_cycled_tile(floor_layer, Vector2i(x, y), FLOOR_VARIANTS, x + y)
			_spawn_cells.append(Vector2i(x, y))


func randomize_turrets() -> void:
	_clear_turrets()

	if turret_scene == null or _spawn_cells.is_empty():
		return

	var available := _spawn_cells.duplicate()
	available.shuffle()

	for i in range(min(turret_count, available.size())):
		_spawn_turret_at_cell(available[i])


func hide_turrets() -> void:
	for turret in _turrets:
		if is_instance_valid(turret):
			turret.hide_turret()


func show_turrets() -> void:
	for turret in _turrets:
		if is_instance_valid(turret):
			turret.show_turret()


func _spawn_turret_at_cell(cell: Vector2i) -> void:
	var turret := turret_scene.instantiate() as Turret
	if turret == null:
		return

	turret_root.add_child(turret)
	_turrets.append(turret)
	turret.position = _cell_to_world(cell)
	turret.snap_hidden()
	turret.show_turret()


func _clear_turrets() -> void:
	for turret in _turrets:
		if is_instance_valid(turret):
			turret.queue_free()
	_turrets.clear()


func _place_cycled_tile(layer: TileMapLayer, cell: Vector2i, variants: Array[Vector2i], seed: int) -> void:
	var atlas_coords := variants[abs(seed) % variants.size()]
	layer.set_cell(cell, FLOOR_SOURCE_ID, atlas_coords, 0)


func _cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * tile_size + tile_size * 0.5, cell.y * tile_size)


func _on_randomize_button_pressed() -> void:
	show_turrets()
	randomize_turrets()


func _on_hide_button_pressed() -> void:
	hide_turrets()


func _on_show_button_pressed() -> void:
	show_turrets()
