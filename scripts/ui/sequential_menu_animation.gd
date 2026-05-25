class_name SequentialMenuAnimation
extends RefCounted

const ITEM_DELAY := 0.06
const SLIDE_DURATION := 0.24
const SLIDE_DISTANCE := 72.0
const START_SCALE := Vector2(0.92, 0.92)


static func play(owner: Node, buttons: Array[Control]) -> void:
	if buttons.is_empty():
		return

	buttons.sort_custom(func(a: Control, b: Control) -> bool:
		return a.global_position.y < b.global_position.y
	)

	for i in buttons.size():
		var button := buttons[i]
		if not is_instance_valid(button):
			continue

		var visual := button.get_node_or_null("Label") as Control
		if visual != null and not visual.has_meta("intro_base_position"):
			visual.set_meta("intro_base_position", visual.position)

		var base_visual_position := Vector2.ZERO
		if visual != null:
			base_visual_position = visual.get_meta("intro_base_position") as Vector2
			visual.position = base_visual_position + Vector2(-SLIDE_DISTANCE, 0.0)

		button.modulate.a = 0.0
		button.scale = START_SCALE
		button.pivot_offset = button.size * 0.5

		var tween := owner.create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_parallel(true)
		if visual != null:
			tween.tween_property(visual, "position", base_visual_position, SLIDE_DURATION).set_delay(i * ITEM_DELAY).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "modulate:a", 1.0, SLIDE_DURATION * 0.72).set_delay(i * ITEM_DELAY)
		tween.tween_property(button, "scale", Vector2.ONE, SLIDE_DURATION).set_delay(i * ITEM_DELAY).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


static func play_exit(owner: Node, buttons: Array[Control]) -> Tween:
	if buttons.is_empty():
		return null

	buttons.sort_custom(func(a: Control, b: Control) -> bool:
		return a.global_position.y < b.global_position.y
	)

	var tween := owner.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)

	for i in buttons.size():
		var button := buttons[i]
		if not is_instance_valid(button):
			continue

		var visual := button.get_node_or_null("Label") as Control
		if visual != null and not visual.has_meta("intro_base_position"):
			visual.set_meta("intro_base_position", visual.position)

		var base_visual_position := Vector2.ZERO
		if visual != null:
			base_visual_position = visual.get_meta("intro_base_position") as Vector2
			visual.position = base_visual_position

		button.pivot_offset = button.size * 0.5
		button.modulate.a = 1.0
		button.scale = Vector2.ONE

		if visual != null:
			tween.tween_property(visual, "position", base_visual_position + Vector2(-SLIDE_DISTANCE, 0.0), SLIDE_DURATION).set_delay(i * ITEM_DELAY).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(button, "modulate:a", 0.0, SLIDE_DURATION * 0.72).set_delay(i * ITEM_DELAY)
		tween.tween_property(button, "scale", START_SCALE, SLIDE_DURATION).set_delay(i * ITEM_DELAY).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	return tween
