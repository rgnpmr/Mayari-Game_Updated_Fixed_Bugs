extends Label

@export var cycle_start_hour : float = 0.0

func _ready() -> void:
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_color_override( "font_shadow_color", Color( 0, 0, 0, 0.6 ) )
	add_theme_constant_override( "shadow_offset_x", 2 )
	add_theme_constant_override( "shadow_offset_y", 2 )

	TimeManager.time_of_day_changed.connect( _on_time_changed )
	_on_time_changed( TimeManager.time_of_day )

func _on_time_changed( t : float ) -> void:
	text = _format_time( t )

func _format_time( t : float ) -> String:
	var total_minutes : int = int( t * 24.0 * 60.0 )
	var hour : int = int( total_minutes / 60.0 ) % 24
	var minute : int = total_minutes % 60
	var period : String = "AM" if hour < 12 else "PM"
	var display_hour : int = hour % 12
	if display_hour == 0:
		display_hour = 12
	return "%02d:%02d %s" % [ display_hour, minute, period ]

func show_hud() -> void:
	visible = true

func hide_hud() -> void:
	visible = false
