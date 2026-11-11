extends Node2D

func _ready() -> void:
	var ap : AnimationPlayer = $AnimationPlayer
	ap.play( "grow" )
	ap.speed_scale = randf_range( 0.85, 1.15 )
	ap.seek( randf() * ap.current_animation_length, true )
