extends Node2D

@export var sway_amount : float = 0.03
@export var sway_speed : float = 1.0

var time_offset : float = randf() * TAU

func _process( delta : float ) -> void:
	time_offset += delta * sway_speed
	rotation = sin( time_offset ) * sway_amount
	pass
