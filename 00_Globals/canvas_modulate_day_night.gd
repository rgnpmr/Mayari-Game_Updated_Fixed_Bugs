extends CanvasModulate

@export var day_color : Color = Color(1.0, 1.0, 1.0)
@export var dusk_color : Color = Color(1.0, 0.55, 0.35)
@export var night_color : Color = Color(0.25, 0.28, 0.45)

@export_range(0.0, 1.0, 0.01) var day_end : float = 0.46
@export_range(0.0, 1.0, 0.01) var dusk_end : float = 0.52
@export_range(0.0, 1.0, 0.01) var night_start : float = 0.58
@export_range(0.0, 1.0, 0.01) var night_end : float = 0.94

func _ready() -> void:
	TimeManager.time_of_day_changed.connect( _on_time_of_day_changed )
	call_deferred( "_on_time_of_day_changed", TimeManager.time_of_day )

func _on_time_of_day_changed( t : float ) -> void:
	color = _get_color_for_time( _to_cycle_time(t) )
	_update_ground_compensation( color )

func _to_cycle_time( t : float ) -> float:
	return fposmod( t - TimeManager.morning_time, 1.0 )

func _get_color_for_time( t : float ) -> Color:
	if t < day_end:
		return day_color
	elif t < dusk_end:
		return day_color.lerp( dusk_color, ( t - day_end ) / ( dusk_end - day_end ) )
	elif t < night_start:
		return dusk_color.lerp( night_color, ( t - dusk_end ) / ( night_start - dusk_end ) )
	elif t < night_end:
		return night_color
	else:
		return night_color.lerp( day_color, ( t - night_end ) / ( 1.0 - night_end ) )

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
