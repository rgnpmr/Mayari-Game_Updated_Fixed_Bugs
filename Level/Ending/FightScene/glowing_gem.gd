extends Node2D

## The gem's picture. Drag one of your gem images here.
@export var gem_texture : Texture2D
## The color of the glow around the gem
@export var glow_color : Color = Color( 1.0, 0.2, 0.2 )
## How wide the glow is, in pixels
@export var glow_size : float = 70.0
## How bright the glow gets at its strongest (0 to 1)
@export_range( 0.0, 1.0 ) var glow_strength : float = 0.85
## Seconds for the glow to get bright and dim again
@export var pulse_seconds : float = 1.6
## How far the gem floats up and down, in pixels
@export var float_height : float = 3.0
@export var float_seconds : float = 2.4
## Little sparkles drifting up from the gem
@export var sparkles : bool = true
## On: the gem is hidden until a dialogue line reveals it
@export var start_hidden : bool = true
## Seconds the gem takes to fade in
@export var reveal_seconds : float = 1.2

var _body : Node2D
var _glow : Sprite2D


func _ready() -> void:
	add_to_group( "story_gems" )
	_body = Node2D.new()
	add_child( _body )

	# The glow: a soft round light that adds to what is behind it
	_glow = Sprite2D.new()
	_glow.texture = _make_glow_texture()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = mat
	_glow.modulate = Color( glow_color.r, glow_color.g, glow_color.b, glow_strength )
	_glow.scale = Vector2.ONE * ( glow_size / 128.0 )
	_body.add_child( _glow )

	# The gem
	var gem := Sprite2D.new()
	gem.texture = gem_texture
	gem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_body.add_child( gem )

	if sparkles:
		_body.add_child( _make_sparkles() )

	_start_pulse()
	_start_float()
	
	if start_hidden:
		modulate.a = 0.0
		visible = false


func _start_pulse() -> void:
	var dim := Color( glow_color.r, glow_color.g, glow_color.b, glow_strength * 0.45 )
	var bright := Color( glow_color.r, glow_color.g, glow_color.b, glow_strength )
	var big : Vector2 = Vector2.ONE * ( glow_size / 128.0 )
	var tw := create_tween().set_loops()
	tw.set_parallel( true )
	tw.tween_property( _glow, "modulate", dim, pulse_seconds * 0.5 ).set_trans( Tween.TRANS_SINE ).set_ease( Tween.EASE_IN_OUT )
	tw.tween_property( _glow, "scale", big * 0.85, pulse_seconds * 0.5 ).set_trans( Tween.TRANS_SINE ).set_ease( Tween.EASE_IN_OUT )
	tw.chain().tween_property( _glow, "modulate", bright, pulse_seconds * 0.5 ).set_trans( Tween.TRANS_SINE ).set_ease( Tween.EASE_IN_OUT )
	tw.parallel().tween_property( _glow, "scale", big, pulse_seconds * 0.5 ).set_trans( Tween.TRANS_SINE ).set_ease( Tween.EASE_IN_OUT )


func _start_float() -> void:
	var tw := create_tween().set_loops()
	tw.tween_property( _body, "position:y", -float_height, float_seconds * 0.5 ).set_trans( Tween.TRANS_SINE ).set_ease( Tween.EASE_IN_OUT )
	tw.tween_property( _body, "position:y", float_height, float_seconds * 0.5 ).set_trans( Tween.TRANS_SINE ).set_ease( Tween.EASE_IN_OUT )


func _make_glow_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.colors = PackedColorArray( [ Color( 1, 1, 1, 1 ), Color( 1, 1, 1, 0 ) ] )
	g.offsets = PackedFloat32Array( [ 0.0, 1.0 ] )
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2( 0.5, 0.5 )
	t.fill_to = Vector2( 1.0, 0.5 )
	t.width = 128
	t.height = 128
	return t


func _make_sparkles() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 8
	p.lifetime = 1.8
	p.local_coords = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = glow_size * 0.2
	p.direction = Vector2( 0, -1 )
	p.spread = 30.0
	p.gravity = Vector2( 0, -6 )
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 8.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = Color( glow_color.r, glow_color.g, glow_color.b ).lightened( 0.5 )
	return p

# Fades the gem in. A delay lets the gems appear one after another.
func reveal( delay : float = 0.0 ) -> void:
	visible = true
	var tw := create_tween()
	tw.tween_interval( delay )
	tw.tween_property( self, "modulate:a", 1.0, reveal_seconds ).set_trans( Tween.TRANS_SINE )
