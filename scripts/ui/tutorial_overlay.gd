class_name TutorialOverlay
extends CanvasLayer

@onready var _panel: PanelContainer = $PanelContainer
@onready var _title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var _message_label: Label = $PanelContainer/MarginContainer/VBoxContainer/MessageLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide_message()


func show_message(message: String) -> void:
	visible = true
	_title_label.text = "TUTORIAL"
	_message_label.text = message


func hide_message() -> void:
	visible = false
