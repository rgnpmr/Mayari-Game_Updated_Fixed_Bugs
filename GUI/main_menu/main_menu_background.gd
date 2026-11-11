extends Node2D

const BIRD_SCENE : PackedScene = preload("res://GUI/main_menu/bird.tscn")

func _ready() -> void:
	_schedule_next_bird()
	pass

func _schedule_next_bird() -> void:
	get_tree().create_timer( randf_range( 1.5, 3.5 ) ).timeout.connect( _spawn_bird )
	pass

func _spawn_bird() -> void:
	var bird = BIRD_SCENE.instantiate()
	bird.global_position = Vector2( -50, randf_range( 50, 200 ) )  # off-screen left, random height
	add_child( bird )
	_schedule_next_bird()
	pass
