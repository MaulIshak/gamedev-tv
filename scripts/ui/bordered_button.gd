@tool
class_name BorderedMenuButton
extends Control

signal pressed

@export var text := "BUTTON":
	set(value):
		text = value
		_refresh_text()

@export var idle_color: Color = Color(0.73, 0.78, 0.74, 0.96):
	set(value):
		idle_color = value
		_refresh_style()

@export var hover_color: Color = Color(0.88, 0.94, 0.86, 0.98):
	set(value):
		hover_color = value
		_refresh_style()

@export var pressed_color: Color = Color(1.0, 0.80, 0.14, 1.0):
	set(value):
		pressed_color = value
		_refresh_style()

@export var active_color: Color = Color(1.0, 0.82, 0.16, 1.0):
	set(value):
		active_color = value
		_refresh_style()

@export var border_color: Color = Color(0.015, 0.035, 0.045, 1.0):
	set(value):
		border_color = value
		_refresh_style()

@export var active := false:
	set(value):
		active = value
		_refresh_style()

@onready var _background: ColorRect = $Background
@onready var _label: Label = $Label

var _hovered := false
var _pressed_inside := false
var _box_material: ShaderMaterial
var _text_material: ShaderMaterial
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_box_material = _background.material.duplicate() as ShaderMaterial
	_text_material = _label.material.duplicate() as ShaderMaterial
	_background.material = _box_material
	_label.material = _text_material
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_refresh_text()
	_refresh_style()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_refresh_style()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_pressed_inside = event.pressed
		if event.pressed:
			_animate_motion(Vector2(0.97, 0.97), Vector2(1.0, 1.0), 0.05)
		elif _hovered:
			_animate_motion(Vector2(1.04, 1.04), Vector2(1.5, -1.0), 0.07)
		else:
			_animate_motion(Vector2.ONE, Vector2.ZERO, 0.08)
		_refresh_style()
		if not event.pressed and get_global_rect().has_point(get_global_mouse_position()):
			pressed.emit()


func _on_mouse_entered() -> void:
	_hovered = true
	_animate_motion(Vector2(1.04, 1.04), Vector2(1.5, -1.0), 0.08)
	_refresh_style()


func _on_mouse_exited() -> void:
	_hovered = false
	_pressed_inside = false
	_animate_motion(Vector2.ONE, Vector2.ZERO, 0.10)
	_refresh_style()


func _refresh_text() -> void:
	if not is_node_ready():
		return
	_label.text = text.to_upper()


func _refresh_style() -> void:
	if not is_node_ready():
		return

	var fill := idle_color
	if active:
		fill = active_color
	if _hovered:
		fill = hover_color
	if _pressed_inside:
		fill = pressed_color

	_box_material.set_shader_parameter("fill_color", fill)
	_box_material.set_shader_parameter("outline_color", border_color)
	_box_material.set_shader_parameter("rect_size", size)

	var text_color := Color(0.05, 0.08, 0.09, 1.0)
	if active or _pressed_inside:
		text_color = Color(0.02, 0.025, 0.03, 1.0)
	_text_material.set_shader_parameter("fill_color", text_color)


func _animate_motion(target_scale: Vector2, label_offset: Vector2, duration: float) -> void:
	pivot_offset = size * 0.5
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.set_parallel(true)
	_tween.tween_property(self, "scale", target_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_label, "position", label_offset, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
