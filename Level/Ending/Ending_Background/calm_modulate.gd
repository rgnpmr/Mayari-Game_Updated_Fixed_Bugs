extends CanvasModulate

## The light the scene starts with
@export var calm_color : Color = Color( 1.0, 0.97, 0.88 )
## The dark light it slowly turns into (like night coming)
@export var dark_color : Color = Color( 0.3, 0.33, 0.5 )
## On: it starts getting dark when the scene starts
@export var autostart : bool = true
## Seconds for it to go from the calm light to the dark light
@export var darken_seconds : float = 20.0
## Seconds to wait before it starts getting dark
@export var start_delay : float = 0.0

var _tween : Tween


func _ready() -> void:
	add_to_group( "story_light" )
	color = calm_color
	call_deferred( "_update_ground_compensation", calm_color )
	if autostart:
		go_dark()


# Slowly turns the light dark
func go_dark( seconds : float = -1.0 ) -> void:
	_fade_to( dark_color, darken_seconds if seconds < 0.0 else seconds )


# Slowly brings the calm light back
func brighten( seconds : float = 4.0 ) -> void:
	_fade_to( calm_color, seconds )


func _fade_to( goal : Color, seconds : float ) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	if start_delay > 0.0 and goal == dark_color:
		_tween.tween_interval( start_delay )
	_tween.tween_method( _set_light, color, goal, seconds ).set_trans( Tween.TRANS_SINE ).set_ease( Tween.EASE_IN_OUT )


func _set_light( c : Color ) -> void:
	color = c
	_update_ground_compensation( c )


# Keeps the ground shader looking right under the tint, same as the original script
func _update_ground_compensation( tint : Color ) -> void:
	if not is_inside_tree():
		return

	var compensation := Vector3(
		1.0 / max( tint.r, 0.01 ),
		1.0 / max( tint.g, 0.01 ),
		1.0 / max( tint.b, 0.01 )
	)

	var ground_nodes := get_tree().get_nodes_in_group( "ground" )
	for ground in ground_nodes:
		if ground.material and ground.material is ShaderMaterial:
			ground.material.set_shader_parameter( "modulate_compensation", compensation )
