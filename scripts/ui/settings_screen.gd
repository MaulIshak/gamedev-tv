class_name SettingsScreen
extends Control

signal back_requested
signal grid_brightness_changed(value: float)
signal hud_scale_changed(value: float)

const CONFIG_PATH := "user://settings.cfg"
const INTRO_OFFSET := Vector2(0.0, -46.0)
const INTRO_DURATION := 0.22

@onready var title_label: Label = $Title
@onready var gameplay_tab = $Panel/Tabs/GameplayTab
@onready var display_tab = $Panel/Tabs/DisplayTab
@onready var audio_tab = $Panel/Tabs/AudioTab
@onready var access_tab = $Panel/Tabs/AccessTab
@onready var gameplay_panel: Control = $Panel/GameplayPanel
@onready var display_panel: Control = $Panel/DisplayPanel
@onready var audio_panel: Control = $Panel/AudioPanel
@onready var resolution_option: OptionButton = $Panel/DisplayPanel/ResolutionOption
@onready var fullscreen_check: CheckButton = $Panel/DisplayPanel/FullscreenCheck
@onready var pixel_filter_option: OptionButton = $Panel/DisplayPanel/PixelFilterOption
@onready var grid_brightness_slider: HSlider = $Panel/GameplayPanel/GridBrightnessSlider
@onready var screen_shake_option: OptionButton = $Panel/GameplayPanel/ScreenShakeOption
@onready var master_slider: HSlider = $Panel/AudioPanel/MasterSlider
@onready var bgm_slider: HSlider = $Panel/AudioPanel/BgmSlider
@onready var sfx_slider: HSlider = $Panel/AudioPanel/SfxSlider
@onready var status_label: Label = $Panel/StatusLabel

var _resolutions: Array[Vector2i] = [
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]
var _base_position: Vector2
var _intro_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_base_position = position
	_populate_options()
	_connect_controls()
	_load_settings()
	_show_tab(gameplay_panel)


func play_intro() -> void:
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()

	position = _base_position + INTRO_OFFSET
	modulate.a = 0.0
	_intro_tween = create_tween()
	_intro_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_intro_tween.set_parallel(true)
	_intro_tween.tween_property(self, "position", _base_position, INTRO_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_intro_tween.tween_property(self, "modulate:a", 1.0, INTRO_DURATION * 0.75)


func _populate_options() -> void:
	resolution_option.clear()
	for resolution in _resolutions:
		resolution_option.add_item("%d x %d" % [resolution.x, resolution.y])

	pixel_filter_option.clear()
	pixel_filter_option.add_item("SHARP")
	pixel_filter_option.add_item("SMOOTH")

	screen_shake_option.clear()
	screen_shake_option.add_item("OFF")
	screen_shake_option.add_item("LOW")
	screen_shake_option.add_item("FULL")


func _connect_controls() -> void:
	gameplay_tab.pressed.connect(_show_tab.bind(gameplay_panel))
	display_tab.pressed.connect(_show_tab.bind(display_panel))
	audio_tab.pressed.connect(_show_tab.bind(audio_panel))
	$Panel/BackButton.pressed.connect(func() -> void: back_requested.emit())
	$Panel/ApplyButton.pressed.connect(_apply_and_save)

	grid_brightness_slider.value_changed.connect(func(value: float) -> void:
		grid_brightness_changed.emit(value)
	)
	master_slider.value_changed.connect(_set_bus_volume.bind("Master"))
	bgm_slider.value_changed.connect(_set_bus_volume.bind("BGM"))
	sfx_slider.value_changed.connect(_set_bus_volume.bind("SFX"))


func _show_tab(panel: Control) -> void:
	gameplay_panel.visible = panel == gameplay_panel
	display_panel.visible = panel == display_panel
	audio_panel.visible = panel == audio_panel

	gameplay_tab.active = gameplay_panel.visible
	display_tab.active = display_panel.visible
	audio_tab.active = audio_panel.visible


func _apply_and_save() -> void:
	_apply_display_settings()
	_apply_audio_settings()
	_save_settings()
	status_label.text = "CONFIG SAVED"
	GlobalEventBus.emit_settings_applied()


func _apply_display_settings() -> void:
	var resolution := _resolutions[clampi(resolution_option.selected, 0, _resolutions.size() - 1)]
	DisplayServer.window_set_size(resolution)
	var screen := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen)
	DisplayServer.window_set_position((screen_size - resolution) / 2)

	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_check.button_pressed else DisplayServer.WINDOW_MODE_WINDOWED
	)

	ProjectSettings.set_setting(
		"rendering/textures/canvas_textures/default_texture_filter",
		pixel_filter_option.selected
	)


func _apply_audio_settings() -> void:
	_set_bus_volume(master_slider.value, "Master")
	_set_bus_volume(bgm_slider.value, "BGM")
	_set_bus_volume(sfx_slider.value, "SFX")

func _set_bus_volume(value: float, bus_name: String) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(maxf(value / 100.0, 0.001)))
	AudioServer.set_bus_mute(bus_idx, value <= 0.0)


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "resolution", resolution_option.selected)
	config.set_value("display", "fullscreen", fullscreen_check.button_pressed)
	config.set_value("display", "pixel_filter", pixel_filter_option.selected)
	config.set_value("gameplay", "grid_brightness", grid_brightness_slider.value)
	config.set_value("gameplay", "screen_shake", screen_shake_option.selected)
	config.set_value("audio", "master", master_slider.value)
	config.set_value("audio", "bgm", bgm_slider.value)
	config.set_value("audio", "sfx", sfx_slider.value)
	config.save(CONFIG_PATH)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		_apply_and_save()
		return

	resolution_option.selected = int(config.get_value("display", "resolution", 1))
	fullscreen_check.button_pressed = bool(config.get_value("display", "fullscreen", false))
	pixel_filter_option.selected = int(config.get_value("display", "pixel_filter", 0))
	grid_brightness_slider.value = float(config.get_value("gameplay", "grid_brightness", 72.0))
	screen_shake_option.selected = int(config.get_value("gameplay", "screen_shake", 1))
	master_slider.value = float(config.get_value("audio", "master", 100.0))
	bgm_slider.value = float(config.get_value("audio", "bgm", 80.0))
	sfx_slider.value = float(config.get_value("audio", "sfx", 90.0))
	_apply_display_settings()
	_apply_audio_settings()
	grid_brightness_changed.emit(grid_brightness_slider.value)
