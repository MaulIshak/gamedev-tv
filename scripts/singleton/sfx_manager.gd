extends Node

@export var pool_size: int = 16
@export var fade_in_duration: float = 0.12
@export var fade_in_start_db: float = -30.0

var _available_players: Array[AudioStreamPlayer] = []
var _fade_tweens: Dictionary = {}
var _last_play_by_key: Dictionary = {}

func _ready() -> void:
	# Pre-allocation
	for i in range(pool_size):
		var audio_player = AudioStreamPlayer.new()
		add_child(audio_player)

		# Mengikat parameter player ke dalam sinyal agar kita tahu siapa yang selesai.
		audio_player.finished.connect(_on_player_finished.bind(audio_player))
		_available_players.append(audio_player)

func play_sfx(stream: AudioStream, bus: StringName = &"Master", volume_db: float = 0.0, fade_in: bool = false, random_pitch: bool = false) -> AudioStreamPlayer:
	if stream == null:
		push_warning("SFXManager: Stream null, batalkan play_sfx.")
		return null

	if _available_players.is_empty():
		push_warning("SFXManager: Pool habis, tidak bisa memutar SFX baru.")
		return null

	var player: AudioStreamPlayer = _available_players.pop_back()
	_clear_fade_tween(player)
	player.stream = stream
	player.bus = bus
	player.pitch_scale = randf_range(0.95, 1.05) if random_pitch else 1.0

	if fade_in:
		player.volume_db = fade_in_start_db
	else:
		player.volume_db = volume_db

	player.play()
	print("[SfxManager] play_sfx: player=", player.get_instance_id(), " stream=", stream.resource_path)

	if fade_in:
		var tween := create_tween()
		var id := player.get_instance_id()
		_fade_tweens[id] = tween
		tween.tween_property(player, "volume_db", volume_db, fade_in_duration)
		tween.finished.connect(_on_fade_tween_finished.bind(id), CONNECT_ONE_SHOT)

	return player

func play_sfx_limited(
	stream: AudioStream,
	bus: StringName = &"Master",
	volume_db: float = 0.0,
	fade_in: bool = false,
	random_pitch: bool = false,
	min_interval_sec: float = 0.0,
	max_simultaneous: int = 0,
	key: StringName = &""
) -> AudioStreamPlayer:
	if stream == null:
		return null

	var resolved_key: StringName = key
	if resolved_key.is_empty():
		resolved_key = StringName(stream.resource_path if not stream.resource_path.is_empty() else str(stream.get_instance_id()))

	if min_interval_sec > 0.0 and _last_play_by_key.has(resolved_key):
		var last_time: float = _last_play_by_key[resolved_key]
		if Time.get_ticks_msec() * 0.001 - last_time < min_interval_sec:
			return null

	if max_simultaneous > 0 and _count_playing_instances(stream) >= max_simultaneous:
		return null

	var player := play_sfx(stream, bus, volume_db, fade_in, random_pitch)
	if player != null:
		_last_play_by_key[resolved_key] = Time.get_ticks_msec() * 0.001
	return player

func is_sfx_playing(stream: AudioStream) -> bool:
	if stream == null:
		return false

	var target_path := stream.resource_path

	for child in get_children():
		var player := child as AudioStreamPlayer
		if player == null:
			continue
		if not player.playing or player.stream == null:
			continue

		if player.stream == stream:
			return true

		if not target_path.is_empty() and player.stream.resource_path == target_path:
			return true

	return false

func play_sfx_once(stream: AudioStream, bus: StringName = &"Master", volume_db: float = 0.0, fade_in: bool = false, random_pitch: bool = false) -> AudioStreamPlayer:
	if is_sfx_playing(stream):
		return null

	return play_sfx(stream, bus, volume_db, fade_in, random_pitch)

func stop_sfx(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player):
		push_warning("SFXManager: Mencoba menghentikan player yang tidak valid.")
		return

	_clear_fade_tween(player)

	player.stop()
	_on_player_finished(player)


func stop_sfx_by_stream(stream: AudioStream) -> void:
	if stream == null:
		return

	var target_path := stream.resource_path
	for child in get_children():
		var player := child as AudioStreamPlayer
		if player == null:
			continue
		if not player.playing or player.stream == null:
			continue

		var matches := false
		if player.stream == stream:
			matches = true
		elif not target_path.is_empty() and player.stream.resource_path == target_path:
			matches = true

		if matches:
			print("[SfxManager] stop_sfx_by_stream: stopping player=", player.get_instance_id(), " stream=", player.stream.resource_path)
			_clear_fade_tween(player)
			player.stop()
			# ensure immediate cleanup and return to pool
			_on_player_finished(player)

func _on_player_finished(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player):
		return

	if _available_players.has(player):
		return

	_clear_fade_tween(player)

	# Kembalikan state dan masukkan kembali ke antrean
	player.stream = null
	_available_players.append(player)

func _clear_fade_tween(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player):
		return

	var id := player.get_instance_id()
	if not _fade_tweens.has(id):
		return

	var tween: Tween = _fade_tweens[id]
	if is_instance_valid(tween):
		tween.kill()

	_fade_tweens.erase(id)

func _on_fade_tween_finished(id: int) -> void:
	_fade_tweens.erase(id)

func _count_playing_instances(stream: AudioStream) -> int:
	if stream == null:
		return 0

	var count := 0
	var target_path := stream.resource_path

	for child in get_children():
		var player := child as AudioStreamPlayer
		if player == null:
			continue
		if not player.playing or player.stream == null:
			continue

		if player.stream == stream:
			count += 1
			continue

		if not target_path.is_empty() and player.stream.resource_path == target_path:
			count += 1

	return count
