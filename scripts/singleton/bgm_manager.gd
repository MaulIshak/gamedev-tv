extends Node

@export var fade_duration: float = 0.5
@export var target_volume_db: float = -5.0
@export var silent_volume_db: float = -40.0
@export var ambience_volume_db: float = -30.0

var current_bgm: AudioStream = null
var bgm_player: AudioStreamPlayer
var gameplay_bgm: AudioStream
var _transition_tween: Tween


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gameplay_bgm = preload("res://assets/audio/bgm/sparkle.mp3")
    
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	bgm_player.volume_db = silent_volume_db

	play_bgm(gameplay_bgm)


func play_bgm(bgm: AudioStream) -> void:
	if bgm == null:
		return

	if current_bgm == bgm and bgm_player.playing:
		return # Sudah diputar, tidak perlu restart

	if is_instance_valid(_transition_tween):
		_transition_tween.kill()

	_transition_tween = create_tween()

	if bgm_player.playing:
		_transition_tween.tween_property(bgm_player, "volume_db", silent_volume_db, fade_duration)

	_transition_tween.tween_callback(_start_new_bgm.bind(bgm))
	_transition_tween.tween_property(bgm_player, "volume_db", target_volume_db, fade_duration)


func _start_new_bgm(bgm: AudioStream) -> void:
	current_bgm = bgm
	bgm_player.stop()
	bgm_player.stream = current_bgm
	bgm_player.volume_db = silent_volume_db
	bgm_player.play()
