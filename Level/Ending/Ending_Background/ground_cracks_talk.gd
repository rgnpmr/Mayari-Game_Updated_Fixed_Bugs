extends ColorRect

## How many shakes until the ground is fully cracked (only used with grow_step)
@export var shakes_to_full : int = 6
## How much is cracked after the very first shake (0 to 1)
@export_range( 0.0, 1.0 ) var first_crack : float = 0.12
## Seconds the cracks take to spread after each shake
@export var spread_seconds : float = 0.5
## Size of one crack pixel, in map units. Bigger = chunkier.
@export var pixel_size : float = 4.0
## How much of the ground is cracked when the scene starts (0 = none, 0.2 = a few small cracks)
@export_range( 0.0, 1.0 ) var start_amount : float = 0.0
## Seconds for the starting cracks to appear
@export var start_seconds : float = 2.0

var _mat : ShaderMaterial
var _progress : float = 0.0
var _count : int = 0
var _tween : Tween


func _ready() -> void:
	add_to_group( "story_cracks" )
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = material as ShaderMaterial
	if _mat == null:
		push_warning( "GroundCracks: add a ShaderMaterial first." )
		return
	_mat = _mat.duplicate() as ShaderMaterial
	material = _mat
	_mat.set_shader_parameter( "aspect", Vector2( size.x / size.y, 1.0 ) )
	_mat.set_shader_parameter( "pixels", size / pixel_size )
	_set_progress( 0.0 )
	if start_amount > 0.0:
		set_cracks( start_amount, start_seconds )


# Cracks the ground to this amount (0 to 1) over some seconds
func set_cracks( amount : float, seconds : float = 1.0 ) -> void:
	if _mat == null:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method( _set_progress, _progress, clampf( amount, 0.0, 1.0 ), seconds ).set_trans( Tween.TRANS_SINE ).set_ease( Tween.EASE_IN_OUT )


# Makes the cracks fade away
func heal( seconds : float = 2.0 ) -> void:
	set_cracks( 0.0, seconds )


# Call this once for every shake. Every call cracks the ground a bit more.
func grow_step() -> void:
	if _mat == null:
		return
	_count += 1
	var last : float = float( maxi( shakes_to_full - 1, 1 ) )
	var goal : float = first_crack + ( 1.0 - first_crack ) * float( _count - 1 ) / last
	set_cracks( minf( goal, 1.0 ), spread_seconds )


# Goes back to clean ground
func reset_cracks() -> void:
	_count = 0
	_set_progress( 0.0 )


func _set_progress( v : float ) -> void:
	_progress = v
	_mat.set_shader_parameter( "progress", v )
