extends CanvasLayer

@onready var rain_particles : GPUParticles2D = $RainParticles
@onready var lightning_flash : ColorRect = $LightningFlash
@onready var rain_loop_player : AudioStreamPlayer = $RainLoopPlayer
@onready var thunder_player : AudioStreamPlayer = $ThunderPlayer
@onready var lightning_timer : Timer = $LightningTimer

@export var rain_loop_sound : AudioStream
@export var thunder_sounds : Array[AudioStream] = []

@export var min_lightning_interval : float = 6.0
@export var max_lightning_interval : float = 18.0
@export var thunder_delay_min : float = 0.3
@export var thunder_delay_max : float = 2.0

## On: the storm starts by itself when the scene starts
@export var autostart : bool = true
## On: the rain covers the whole screen, whatever size it is
@export var fit_rain_to_screen : bool = true
## On: this script also flashes the screen. Turn it off if the Lightning scene already does.
@export var use_screen_flash : bool = true

var storm_active : bool = false

func _ready() -> void:
	lightning_flash.color = Color(1, 1, 1, 0)
	lightning_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lightning_flash.set_anchors_preset( Control.PRESET_FULL_RECT )
	lightning_timer.timeout.connect( _on_lightning_timer_timeout )
	visible = false

	if fit_rain_to_screen:
		_fit_rain()

	if autostart:
		start_storm()

# Makes the rain fall over the whole screen
func _fit_rain() -> void:
	var screen : Vector2 = get_viewport().get_visible_rect().size
	var mat := rain_particles.process_material as ParticleProcessMaterial
	if mat == null:
		return
	mat = mat.duplicate() as ParticleProcessMaterial
	rain_particles.process_material = mat
	if mat.emission_shape == ParticleProcessMaterial.EMISSION_SHAPE_BOX:
		mat.emission_box_extents = Vector3( screen.x * 0.5, 1.0, 1.0 )
		rain_particles.position = Vector2( screen.x * 0.5, -10.0 )
		rain_particles.visibility_rect = Rect2( -screen.x * 0.5, -20.0, screen.x, screen.y + 60.0 )

func start_storm() -> void:
	storm_active = true
	visible = true
	rain_particles.emitting = true

	if rain_loop_sound:
		rain_loop_player.stream = rain_loop_sound
		rain_loop_player.play()

	_schedule_next_lightning()
	_set_ground_wetness( 1.0, 3.0 )

func stop_storm() -> void:
	storm_active = false
	rain_particles.emitting = false
	rain_loop_player.stop()
	lightning_timer.stop()
	visible = false
	_set_ground_wetness( 0.0, 3.0 )

func _set_ground_wetness( target : float, duration : float ) -> void:
	var ground_nodes := get_tree().get_nodes_in_group( "ground" )
	for ground in ground_nodes:
		if not ground.has_method( "set_wetness" ):
			continue

		var start : float = 0.0
		var mat := ground.material as ShaderMaterial
		if mat:
			var current = mat.get_shader_parameter( "wetness" )
			if current != null:
				start = float( current )

		var tween := create_tween()
		tween.tween_method(
			func( v : float ): ground.set_wetness( v ),
			start,
			target,
			duration
		)

func _schedule_next_lightning() -> void:
	if not storm_active:
		return
	lightning_timer.wait_time = randf_range( min_lightning_interval, max_lightning_interval )
	lightning_timer.start()

func _on_lightning_timer_timeout() -> void:
	if not storm_active:
		return
	_flash_lightning()
	_schedule_next_lightning()

func _flash_lightning() -> void:
	if use_screen_flash:
		var flash_tween := create_tween()
		flash_tween.tween_property( lightning_flash, "color:a", 0.85, 0.05 )
		flash_tween.tween_property( lightning_flash, "color:a", 0.0, 0.15 )
		flash_tween.tween_property( lightning_flash, "color:a", 0.6, 0.05 )
		flash_tween.tween_property( lightning_flash, "color:a", 0.0, 0.3 )

	var delay := randf_range( thunder_delay_min, thunder_delay_max )
	await get_tree().create_timer( delay ).timeout
	_play_thunder()

func _play_thunder() -> void:
	if thunder_sounds.size() == 0:
		return
	thunder_player.stream = thunder_sounds[ randi() % thunder_sounds.size() ]
	thunder_player.pitch_scale = randf_range( 0.9, 1.1 )
	thunder_player.play()
