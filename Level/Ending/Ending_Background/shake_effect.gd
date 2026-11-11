extends Node

@export var pulse_interval_min : float = 3.0
@export var pulse_interval_max : float = 7.0
@export var pulse_strength_min : float = 0.3
@export var pulse_strength_max : float = 0.7
@export var enabled : bool = true
@export var tree_fall : Node

## What shakes. Leave empty to shake the parent (village).
@export var target : Node2D
## The GroundCracks node. It starts cracking on the first shake.
@export var cracks : Node
## The biggest move in pixels at strength 1
@export var max_offset : float = 10.0
## Seconds one shake lasts
@export var shake_duration : float = 0.6
## On: also shake the player's camera like before
@export var use_player_camera : bool = false

var pulse_timer : Timer
var _base : Vector2
var _tween : Tween



func _ready() -> void:
	if target == null:
		target = get_parent() as Node2D
	if target != null:
		_base = target.position

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
		_shake( strength )
		if use_player_camera:
			PlayerManager.shake_camera( strength )
		if cracks != null and cracks.has_method( "grow_step" ):
			cracks.grow_step()
		if tree_fall != null and tree_fall.has_method( "topple_some" ):
			tree_fall.topple_some()
	_schedule_next_pulse()


func _shake( strength : float ) -> void:
	if target == null:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
		target.position = _base

	var steps : int = 10
	_tween = create_tween()
	for i in steps:
		var fade : float = 1.0 - float( i ) / float( steps )
		var off := Vector2( randf_range( -1.0, 1.0 ), randf_range( -1.0, 1.0 ) ) * strength * max_offset * fade
		_tween.tween_property( target, "position", _base + off, shake_duration / float( steps ) )
	_tween.tween_property( target, "position", _base, shake_duration / float( steps ) )


func stop_shaking() -> void:
	enabled = false


func start_shaking() -> void:
	if enabled:
		return
	enabled = true
	_schedule_next_pulse()
