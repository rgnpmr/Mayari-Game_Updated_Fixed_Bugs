extends Node

@export var music_stream: AudioStream = preload("res://Props/background_music/1.wav")
@export var volume_db: float = -6.0
## Other audio buses that are lowered together with the music while a story plays
@export var duck_buses : Array[String] = ["Ambience"]

var player: AudioStreamPlayer
var _base_volume_db: float
var _duck_tween: Tween
var _bus_tween: Tween
var _bus_base_db : Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	player = AudioStreamPlayer.new()
	player.stream = music_stream
	player.volume_db = volume_db
	player.bus = "Music"
	add_child(player)
	_base_volume_db = volume_db
	player.play()

func stop_music() -> void:
	player.stop()

func resume_music() -> void:
	if not player.playing:
		player.play()

func set_music_volume(db: float) -> void:
	_base_volume_db = db
	player.volume_db = db

func duck(amount_db: float = -10.0, fade_time: float = 0.5) -> void:
	_fade_to(_base_volume_db + amount_db, fade_time)
	_fade_buses(amount_db, fade_time, false)

func unduck(fade_time: float = 1.0) -> void:
	_fade_to(_base_volume_db, fade_time)
	_fade_buses(0.0, fade_time, true)

func _fade_to(target_db: float, time: float) -> void:
	if _duck_tween and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_property(player, "volume_db", target_db, time)

# Lowers (or restores) the volume of the other buses, like the ambience
func _fade_buses(amount_db: float, time: float, restore: bool) -> void:
	if _bus_tween and _bus_tween.is_valid():
		_bus_tween.kill()
	_bus_tween = create_tween().set_parallel(true)

	for bus_name in duck_buses:
		var idx : int = AudioServer.get_bus_index(bus_name)
		if idx < 0:
			continue
		# Remember the normal volume the first time, so it can be restored exactly
		if not _bus_base_db.has(bus_name):
			_bus_base_db[bus_name] = AudioServer.get_bus_volume_db(idx)
		var base : float = _bus_base_db[bus_name]
		var target : float = base if restore else base + amount_db
		_bus_tween.tween_method(
			func(v: float): AudioServer.set_bus_volume_db(idx, v),
			AudioServer.get_bus_volume_db(idx),
			target,
			time
		)

	if restore:
		_bus_tween.finished.connect(func(): _bus_base_db.clear())
