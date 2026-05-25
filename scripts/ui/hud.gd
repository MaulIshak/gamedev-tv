extends Node2D

@onready var control: Control = $Control
var heart_tex: Texture = preload("res://assets/sprites/heart.png")
var hearts_container: HBoxContainer
var max_hearts: int = 0

func _ready() -> void:
	hearts_container = control.get_node_or_null("Hearts")
	if hearts_container == null:
		hearts_container = HBoxContainer.new()
		hearts_container.name = "Hearts"
		control.add_child(hearts_container)
		# position inside Control
		hearts_container.anchor_left = 0
		hearts_container.anchor_top = 0
		hearts_container.margin_left = 8
		hearts_container.margin_top = 8

	if GlobalEventBus.is_connected("hearts_changed", self, "_on_hearts_changed") == false:
		GlobalEventBus.connect("hearts_changed", self, "_on_hearts_changed")

	# initialize with default
	_on_hearts_changed(0, 3)

func _on_hearts_changed(current: int, max: int) -> void:
	max_hearts = max
	# clear existing
	for child in hearts_container.get_children():
		child.queue_free()

	for i in range(max_hearts):
		var tex = TextureRect.new()
		tex.texture = heart_tex
		tex.rect_min_size = Vector2(20, 20)
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.modulate = Color(1, 1, 1, 1) if i < current else Color(1, 1, 1, 0.25)
		hearts_container.add_child(tex)
