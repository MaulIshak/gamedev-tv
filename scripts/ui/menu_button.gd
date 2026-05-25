@tool
class_name MainMenuButton
extends Button

@export var button_text: String = "Button":
	set(value):
		button_text = value
		_sync_label()

@export var selected: bool = false:
	set(value):
		selected = value
		_sync_label()

@export var default_material: Material:
	set(value):
		default_material = value
		_sync_label()

@export var selected_material: Material:
	set(value):
		selected_material = value
		_sync_label()

@export_group("Motion")
@export var idle_offset: Vector2 = Vector2.ZERO
@export var hover_offset: Vector2 = Vector2(4.0, 0.0)
@export var pressed_offset: Vector2 = Vector2(2.0, 2.0)
@export var idle_scale: Vector2 = Vector2.ONE
@export var hover_scale: Vector2 = Vector2(1.06, 1.06)
@export var pressed_scale: Vector2 = Vector2(0.98, 0.98)
@export var hover_modulate: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var idle_modulate: Color = Color(0.92, 0.92, 0.92, 1.0)
@export var selected_modulate: Color = Color(1.0, 1.0, 1.0, 1.0)

@export var label_base_position: Vector2 = Vector2(0.0, -1.0)

@onready var label: Label = $Label

var _tween: Tween
var _hovered := false
var _pressed := false


func _ready() -> void:
	text = ""
	flat = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pivot_offset = size * 0.5
	_sync_label()

	if Engine.is_editor_hint():
		return

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size * 0.5


func _sync_label() -> void:
	var target_label := get_node_or_null("Label") as Label
	if target_label == null:
		return

	target_label.text = button_text
	target_label.modulate = selected_modulate if selected else idle_modulate
	if selected and selected_material != null:
		target_label.material = selected_material
	elif not selected and default_material != null:
		target_label.material = default_material

	target_label.position = label_base_position


func _on_mouse_entered() -> void:
	_hovered = true
	grab_focus()
	_animate_state(hover_scale, hover_offset, hover_modulate, 0.10)


func _on_mouse_exited() -> void:
	_hovered = false
	_pressed = false
	_animate_state(idle_scale, idle_offset, selected_modulate if selected else idle_modulate, 0.12)


func _on_button_down() -> void:
	_pressed = true
	_animate_state(pressed_scale, pressed_offset, hover_modulate, 0.06)


func _on_button_up() -> void:
	_pressed = false
	if _hovered:
		_animate_state(hover_scale, hover_offset, hover_modulate, 0.08)
	else:
		_animate_state(idle_scale, idle_offset, selected_modulate if selected else idle_modulate, 0.10)


func _on_focus_entered() -> void:
	if not _hovered and not _pressed:
		_animate_state(hover_scale, hover_offset, hover_modulate, 0.10)


func _on_focus_exited() -> void:
	if not _hovered and not _pressed:
		_animate_state(idle_scale, idle_offset, selected_modulate if selected else idle_modulate, 0.10)


func _animate_state(target_scale: Vector2, label_offset: Vector2, target_modulate: Color, duration: float) -> void:
	if label == null:
		return

	if _tween != null and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", target_scale, duration)
	_tween.tween_property(label, "position", label_base_position + label_offset, duration)
	_tween.tween_property(label, "modulate", target_modulate, duration)
