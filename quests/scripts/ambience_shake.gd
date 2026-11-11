extends Node

@export var pulse_interval_min : float = 3.0
@export var pulse_interval_max : float = 7.0
@export var pulse_strength_min : float = 0.3
@export var pulse_strength_max : float = 0.7
@export var enabled : bool = true

var pulse_timer : Timer

func _ready() -> void:
	pulse_timer = Timer.new()
	add_child( pulse_timer )
	pulse_timer.one_shot = true
	pulse_timer.timeout.connect( _on_pulse_timeout )
	_schedule_next_pulse()

func _schedule_next_pulse() -> void:
	if not enabled:
		return
	pulse_timer.wait_time = randf_range( pulse_interval_min, pulse_interval_max )
	pulse_timer.start()

func _on_pulse_timeout() -> void:
	if enabled:
		var strength : float = randf_range( pulse_strength_min, pulse_strength_max )
		PlayerManager.shake_camera( strength )
	_schedule_next_pulse()

func stop_shaking() -> void:
	enabled = false

func start_shaking() -> void:
	if enabled:
		return
	enabled = true
	_schedule_next_pulse()
