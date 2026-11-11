extends Node2D

## Seconds between strikes: a random time between these two numbers
@export var min_wait : float = 3.0
@export var max_wait : float = 8.0
## Seconds before the very first strike
@export var first_delay : float = 1.0
## Bolt size: a random size between these (relative to a 500 pixel wide screen)
@export var min_scale : float = 1.2
@export var max_scale : float = 2.2

@onready var bolt : AnimatedSprite2D = $Bolt
@onready var flash : ColorRect = $Flash
@onready var player : AnimationPlayer = $AnimationPlayer

# The screen, measured in this node's own units
var _origin : Vector2 = Vector2.ZERO
var _size : Vector2 = Vector2( 500, 300 )


func _ready() -> void:
	_measure_screen()
	await get_tree().create_timer( first_delay ).timeout
	while is_inside_tree():
		strike()
		await get_tree().create_timer( randf_range( min_wait, max_wait ) ).timeout


# Works out where the screen's top-left corner is and how big the screen is,
# even when a parent node is scaled (like village at 0.5)
func _measure_screen() -> void:
	var to_screen : Transform2D = get_global_transform_with_canvas()
	var to_local : Transform2D = to_screen.affine_inverse()
	var screen : Vector2 = get_viewport_rect().size
	_origin = to_local * Vector2.ZERO
	_size = Vector2( to_local.x.length(), to_local.y.length() ) * screen

	# Cover the whole screen with the flash
	flash.set_anchors_preset( Control.PRESET_TOP_LEFT )
	flash.position = _origin
	flash.size = _size


func strike() -> void:
	_measure_screen()
	var fit : float = _size.x / 500.0
	var s : float = randf_range( min_scale, max_scale ) * fit
	bolt.scale = Vector2( s, s )
	bolt.flip_h = randf() < 0.5
	# The widest bolt picture is about 80 pixels, so keep it inside the screen
	var width : float = 80.0 * s
	bolt.position = Vector2(
			_origin.x + randf_range( 0.0, maxf( _size.x - width, 0.0 ) ),
			_origin.y + randf_range( -20.0, 30.0 ) * fit )
	player.play( "strike" )
