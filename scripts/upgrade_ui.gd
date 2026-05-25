class_name UpgradeUI
extends Control

signal upgrade_selected(upgrade_id: String)

@export var player: Player

const ELECTRIC_SHOCK_SFX: AudioStream = preload("res://assets/audio/sfx/electric_shock.mp3")
const ENTER_OFFSET := Vector2(0.0, 92.0)
const ENTER_DELAY := 0.09
const ENTER_DURATION := 0.30
const EXIT_DURATION := 0.22
const BLINK_DURATION := 0.42
const FLOAT_AMOUNT := 3.0

@onready var _backdrop: ColorRect = $Backdrop
@onready var _title: Label = $Cards/Title
@onready var _cards: Array[Button] = [
	$Cards/Left,
	$Cards/Mid,
	$Cards/Right,
]

var _upgrades: Array[UpgradeDef] = []
var _base_positions: Array[Vector2] = []
var _title_base_position := Vector2.ZERO
var _idle_tweens: Array[Tween] = []
var _is_selecting := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_cache_base_positions()
	_title_base_position = _title.position
	for i in range(_cards.size()):
		var card := _cards[i]
		card.process_mode = Node.PROCESS_MODE_ALWAYS
		var back := card.get_node("CardBack") as TextureRect
		if back.material != null:
			back.material = back.material.duplicate()
		card.pressed.connect(_on_card_pressed.bind(i))
		card.mouse_entered.connect(_set_hover.bind(i, true))
		card.mouse_exited.connect(_set_hover.bind(i, false))


func show_upgrades() -> void:
	if _is_selecting:
		return

	_populate()
	show()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.modulate.a = 0.0
	_title.modulate.a = 0.0
	for card in _cards:
		card.disabled = false
		_set_card_shader_value(card, "hover_strength", 0.0)
		_set_card_shader_value(card, "select_strength", 0.0)

	if Engine.has_singleton("SfxManager"):
		SfxManager.stop_sfx_by_stream(ELECTRIC_SHOCK_SFX)
	if player != null:
		player.disable_input()

	_play_enter()


func _populate() -> void:
	_upgrades = UpgradeManager.get_random_upgrades(3)

	for i in range(_cards.size()):
		var card := _cards[i]
		if i < _upgrades.size():
			var def := _upgrades[i]
			card.get_node("Name").text = def.display_name
			card.get_node("Level").text = "LV.%d" % [UpgradeManager.get_level(def.id) + 1]
			card.get_node("Icon").texture = def.get_icon_texture()
			card.show()
		else:
			card.get_node("Icon").texture = null
			card.hide()


func _on_card_pressed(index: int) -> void:
	if _is_selecting or index >= _upgrades.size():
		return

	_is_selecting = true
	for card in _cards:
		card.disabled = true

	var selected_card := _cards[index]
	_set_card_shader_value(selected_card, "hover_strength", 1.0)
	_set_card_shader_value(selected_card, "select_strength", 1.0)

	await get_tree().create_timer(BLINK_DURATION).timeout

	var upgrade_id := _upgrades[index].id
	UpgradeManager.apply_upgrade(upgrade_id)
	await _play_exit()

	upgrade_selected.emit(upgrade_id)
	hide()
	_is_selecting = false
	if player != null:
		player.enable_input()


func _play_enter() -> void:
	_stop_idle_tweens()
	var backdrop_tween := create_tween()
	backdrop_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	backdrop_tween.tween_property(_backdrop, "modulate:a", 1.0, 0.24)

	_title.position = _title_base_position + Vector2(0.0, -14.0)
	var title_tween := create_tween()
	title_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	title_tween.set_parallel(true)
	title_tween.tween_property(_title, "position", _title_base_position, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	title_tween.tween_property(_title, "modulate:a", 1.0, 0.18)

	for i in range(_cards.size()):
		var card := _cards[i]
		card.position = _base_positions[i] + ENTER_OFFSET
		card.modulate.a = 0.0
		card.scale = Vector2(0.94, 0.94)
		card.pivot_offset = card.size * 0.5
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_parallel(true)
		tween.tween_property(card, "position", _base_positions[i], ENTER_DURATION).set_delay(i * ENTER_DELAY).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "modulate:a", 1.0, ENTER_DURATION * 0.75).set_delay(i * ENTER_DELAY)
		tween.tween_property(card, "scale", Vector2.ONE, ENTER_DURATION).set_delay(i * ENTER_DELAY).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.finished.connect(_start_idle_float.bind(i))


func _play_exit() -> Signal:
	_stop_idle_tweens()
	for i in range(_cards.size()):
		var card := _cards[i]
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_parallel(true)
		tween.tween_property(card, "position", _base_positions[i] + ENTER_OFFSET, EXIT_DURATION).set_delay(i * ENTER_DELAY).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(card, "modulate:a", 0.0, EXIT_DURATION * 0.8).set_delay(i * ENTER_DELAY)

	var fade_tween := create_tween()
	fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_tween.set_parallel(true)
	fade_tween.tween_property(_title, "modulate:a", 0.0, EXIT_DURATION)
	fade_tween.tween_property(_backdrop, "modulate:a", 0.0, EXIT_DURATION + ENTER_DELAY * 2.0)
	return fade_tween.finished


func _start_idle_float(index: int) -> void:
	if _is_selecting or index >= _cards.size() or not visible:
		return

	var card := _cards[index]
	card.position = _base_positions[index]
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_loops()
	tween.tween_property(card, "position:y", _base_positions[index].y - FLOAT_AMOUNT, 0.85 + index * 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(card, "position:y", _base_positions[index].y + FLOAT_AMOUNT, 0.85 + index * 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tweens.append(tween)


func _set_hover(index: int, hovered: bool) -> void:
	if _is_selecting or index >= _cards.size():
		return
	_set_card_shader_value(_cards[index], "hover_strength", 1.0 if hovered else 0.0)


func _set_card_shader_value(card: Button, parameter: StringName, value: float) -> void:
	var back := card.get_node("CardBack") as TextureRect
	if back.material is ShaderMaterial:
		var material := back.material as ShaderMaterial
		material.set_shader_parameter(parameter, value)


func _cache_base_positions() -> void:
	_base_positions.clear()
	for card in _cards:
		_base_positions.append(card.position)


func _stop_idle_tweens() -> void:
	for tween in _idle_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_idle_tweens.clear()
