class_name UpgradeUI extends Control

signal upgrade_selected(upgrade_id: String)

@export var player: Player

@onready var _buttons: Array[Button] = [
	$HBoxContainer/Left,
	$HBoxContainer/Mid,
	$HBoxContainer/Right,
]

var _upgrades: Array[UpgradeDef] = []

func _ready() -> void:
	hide()
	for i in range(_buttons.size()):
		_buttons[i].pressed.connect(_on_button_pressed.bind(i))

func show_upgrades() -> void:
	_populate()
	show()
	if player != null:
		player.disable_input()

func _populate() -> void:
	_upgrades = UpgradeManager.get_random_upgrades(3)

	for i in range(_buttons.size()):
		var button := _buttons[i]
		if i < _upgrades.size():
			var def := _upgrades[i]
			button.text = "%s (Lv.%d)" % [def.display_name, UpgradeManager.get_level(def.id) + 1]
			button.show()
		else:
			button.hide()

func _on_button_pressed(index: int) -> void:
	if index >= _upgrades.size():
		return

	var upgrade_id := _upgrades[index].id
	UpgradeManager.apply_upgrade(upgrade_id)
	upgrade_selected.emit(upgrade_id)
	hide()

	if player != null:
		player.enable_input()
