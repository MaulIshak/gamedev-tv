extends Node2D

@onready var control: Control = $Control
@onready var hearts_container: HBoxContainer = $Control/Hearts

var heart_tex: Texture = preload("res://assets/sprites/heartremake.png")
var max_hearts: int = 0

func _ready() -> void:
	# Initially hide the HUD since the game boots to the Main Menu
	visible = false

	# Connect signals using modern Godot 4 Callable syntax
	if not GlobalEventBus.hearts_changed.is_connected(_on_hearts_changed):
		GlobalEventBus.hearts_changed.connect(_on_hearts_changed)
	if not GlobalEventBus.play_requested.is_connected(_on_play_requested):
		GlobalEventBus.play_requested.connect(_on_play_requested)
	if not GlobalEventBus.main_menu_requested.is_connected(_on_main_menu_requested):
		GlobalEventBus.main_menu_requested.connect(_on_main_menu_requested)
	if not GlobalEventBus.restart_requested.is_connected(_on_restart_requested):
		GlobalEventBus.restart_requested.connect(_on_restart_requested)

func _on_play_requested() -> void:
	visible = true

func _on_main_menu_requested() -> void:
	visible = false

func _on_restart_requested() -> void:
	visible = true

func _on_hearts_changed(current: int, max_val: int) -> void:
	max_hearts = max_val
	# Clear existing heart textures
	for child in hearts_container.get_children():
		child.queue_free()

	for i in range(max_hearts):
		var atlas_tex := AtlasTexture.new()
		atlas_tex.atlas = heart_tex
		
		# Each heart in heartremake.png is 32x32:
		# Left tile (0, 0, 32, 32) is the full red heart
		# Right tile (32, 0, 32, 32) is the empty dark red outline heart
		if i < current:
			atlas_tex.region = Rect2(0, 0, 32, 32)
		else:
			atlas_tex.region = Rect2(32, 0, 32, 32)

		var tex := TextureRect.new()
		tex.texture = atlas_tex
		tex.custom_minimum_size = Vector2(32, 32)
		tex.stretch_mode = TextureRect.STRETCH_SCALE
		
		hearts_container.add_child(tex)
