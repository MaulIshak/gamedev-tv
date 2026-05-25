class_name Connection extends Line2D

signal expired(from_tower: Node2D, to_tower: Node2D)
signal visual_finished(from_tower: Node2D, to_tower: Node2D)

var start_pos: Node2D
var end_pos: Node2D
var offset: Vector2 = Vector2.ZERO
var start_offset: Vector2 = Vector2.ZERO
var end_offset: Vector2 = Vector2.ZERO

var _timer: float = -1.0
var _visual_finished_emitted: bool = false


@onready var damage_zone := get_node_or_null("DamageZone") as Area2D
@onready var collision_shape := get_node_or_null("DamageZone/CollisionShape2D") as CollisionShape2D
@onready var start_spot := get_node_or_null("StartSpot") as Sprite2D
@onready var end_spot := get_node_or_null("EndSpot") as Sprite2D

func _ready() -> void:
	if collision_shape != null:
		collision_shape.shape = SegmentShape2D.new()
	points = [Vector2.ZERO, Vector2.ZERO]

func _process(delta: float) -> void:
	if start_pos != null and end_pos != null:
		points[0] = start_pos.position + offset + start_offset
		points[1] = end_pos.position + offset + end_offset

		if start_spot != null:
			start_spot.position = points[0]
			start_spot.z_index = max(start_spot.z_index, 20)
		if end_spot != null:
			end_spot.position = points[1]
			end_spot.z_index = max(end_spot.z_index, 20)

		if damage_zone and collision_shape and collision_shape.shape is SegmentShape2D:
			var seg := collision_shape.shape as SegmentShape2D
			seg.a = damage_zone.to_local(to_global(points[0]))
			seg.b = damage_zone.to_local(to_global(points[1]))

	if _timer > 0.0:
		_timer -= delta
		if _timer <= 0.0:
			_timer = -1.0
			# notify expired and visual finished before freeing so managers can react
			expired.emit(start_pos, end_pos)
			if not _visual_finished_emitted:
				emit_signal("visual_finished", start_pos, end_pos)
				_visual_finished_emitted = true
			queue_free()

func start_timer(duration: float) -> void:
	_timer = duration

func get_time_left() -> float:
	return _timer if _timer > 0.0 else 0.0

func set_timer(duration: float) -> void:
	_timer = duration

func _exit_tree() -> void:
	# If node is removed/queued from elsewhere (clear_all_connections or manual queue_free),
	# ensure we emit visual_finished once so sound managers can stop looping audio.
	if not _visual_finished_emitted:
		emit_signal("visual_finished", start_pos, end_pos)
		_visual_finished_emitted = true
